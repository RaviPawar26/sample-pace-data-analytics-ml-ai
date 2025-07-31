package com.hackathon;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.amazonaws.services.kinesisanalytics.runtime.KinesisAnalyticsRuntime;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Properties;
import java.io.IOException;

import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.functions.RichMapFunction;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.java.utils.ParameterTool;
import org.apache.flink.formats.json.JsonDeserializationSchema;
import org.apache.flink.formats.json.JsonSerializationSchema;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.LocalStreamEnvironment;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerializationSchema;
import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.util.Collector;
import org.apache.flink.util.OutputTag;

public class KafkaStreamingJob {

        private static final String DEFAULT_SOURCE_TOPIC = "intraday-source-topic";
        private static final String DEFAULT_SINK_TOPIC = "intraday-sink-topic";

        private static final Logger LOG = LoggerFactory.getLogger(KafkaStreamingJob.class);
        
        // Define a side output for error events
        private static final OutputTag<String> ERROR_OUTPUT = new OutputTag<String>("error-events"){};

        private static ParameterTool loadApplicationParameters(String[] args, StreamExecutionEnvironment env)
                        throws IOException {
                if (env instanceof LocalStreamEnvironment) {
                        return ParameterTool.fromArgs(args);
                } else {
                        Map<String, Properties> applicationProperties = KinesisAnalyticsRuntime
                                        .getApplicationProperties();
                        Properties flinkProperties = applicationProperties.get("FlinkApplicationProperties");
                        if (flinkProperties == null) {
                                throw new RuntimeException(
                                                "Unable to load FlinkApplicationProperties properties from runtime properties");
                        }
                        Map<String, String> map = new HashMap<>(flinkProperties.size());
                        flinkProperties.forEach((k, v) -> map.put((String) k, (String) v));
                        return ParameterTool.fromMap(map);
                }
        }

        private static Properties getKafkaProperties(ParameterTool applicationProperties, String startsWith) {
                Properties properties = new Properties();
                applicationProperties.getProperties().forEach((key, value) -> {
                        Optional.ofNullable(key).map(Object::toString).filter(k -> {
                                return k.startsWith(startsWith);
                        })
                                        .ifPresent(k -> {
                                                properties.put(k.substring(startsWith.length()), value);
                                        });
                });

                return properties;
        }

        public static void main(String[] args) throws Exception {
                try {
                        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

                        env.disableOperatorChaining();

                        // Configure checkpointing and error handling
                        env.getCheckpointConfig().setTolerableCheckpointFailureNumber(3);
                        
                        // Set up exception handler for the environment
                        env.getConfig().setGlobalJobParameters(ParameterTool.fromMap(new HashMap<>()));

                        final ParameterTool applicationProperties = loadApplicationParameters(args, env);

                        String region = applicationProperties.get("aws.region", "us-east-1");
                        String sourceTopic = applicationProperties.get("source.topic", DEFAULT_SOURCE_TOPIC);
                        String bootstrapServers = applicationProperties.get("bootstrap.servers");

                        if (bootstrapServers == null || bootstrapServers.isEmpty()) {
                                LOG.error("Bootstrap servers configuration is missing");
                                throw new IllegalArgumentException("Bootstrap servers must be configured");
                        }

                        LOG.info("Using region: {}", region);
                        LOG.info("Using source topic: {}", sourceTopic);
                        LOG.info("Using bootstrap servers: {}", bootstrapServers);

                        KafkaSource<IncomingEvent> source = KafkaSource.<IncomingEvent>builder()
                                        .setBootstrapServers(bootstrapServers)
                                        .setTopics(sourceTopic)
                                        .setGroupId("flink-kafka-consumer-group")
                                        .setStartingOffsets(OffsetsInitializer.latest())
                                        .setValueOnlyDeserializer(new JsonDeserializationSchema<>(IncomingEvent.class))
                                        .setProperties(getKafkaProperties(applicationProperties, "source."))
                                        .build();

                        WatermarkStrategy<IncomingEvent> watermarkStrategy = WatermarkStrategy.noWatermarks();

                        DataStream<IncomingEvent> stream = env.fromSource(source, watermarkStrategy, "source");
                        
                        // Process incoming events with error handling
                        SingleOutputStreamOperator<IncomingEvent> processedStream = stream
                                .process(new ProcessFunction<IncomingEvent, IncomingEvent>() {
                                        @Override
                                        public void processElement(IncomingEvent event, Context ctx, Collector<IncomingEvent> out) {
                                                try {
                                                        // Validate event
                                                        if (event == null) {
                                                                throw new IllegalArgumentException("Received null event");
                                                        }
                                                        
                                                        if (event.getAccount() == null || event.getAccount().isEmpty()) {
                                                                throw new IllegalArgumentException("Event missing account information");
                                                        }
                                                        
                                                        // Log successful event receipt
                                                        LOG.info("Received event from source topic {}: account={}, payload Type={}, payload={}", 
                                                                sourceTopic, event.getAccount(), event.getPayloadType(), event.getPayload());
                                                        
                                                        // Pass valid event downstream
                                                        out.collect(event);
                                                } catch (Exception e) {
                                                        // Log error and send to side output
                                                        String errorMsg = String.format("Error processing event: %s - %s", 
                                                                e.getClass().getName(), e.getMessage());
                                                        LOG.error(errorMsg, e);
                                                        ctx.output(ERROR_OUTPUT, errorMsg);
                                                }
                                        }
                                });
                        
                        // Get error events for potential error handling/dead letter queue
                        DataStream<String> errorEvents = processedStream.getSideOutput(ERROR_OUTPUT);
                        
                        // Log error events (could be sent to a dead letter queue/topic)
                        errorEvents.map(new MapFunction<String, String>() {
                                @Override
                                public String map(String errorMsg) throws Exception {
                                        LOG.error("Error event sent to dead letter channel: {}", errorMsg);
                                        return errorMsg;
                                }
                        });

                        // Get sink topic name from properties
                        String sinkTopic = applicationProperties.get("sink.topic", DEFAULT_SINK_TOPIC);
                        LOG.info("Configuring sink to topic: {}", sinkTopic);

                        KafkaRecordSerializationSchema<IncomingEvent> serializer = KafkaRecordSerializationSchema
                                        .<IncomingEvent>builder()
                                        .setTopic(sinkTopic)
                                        .setValueSerializationSchema(new JsonSerializationSchema<>())
                                        .build();

                        KafkaSink<IncomingEvent> kafkaSink = KafkaSink.<IncomingEvent>builder()
                                        .setBootstrapServers(bootstrapServers)
                                        .setKafkaProducerConfig(getKafkaProperties(applicationProperties, "sink."))
                                        .setRecordSerializer(serializer)
                                        .build();

                        // Add final processing step with error handling before sending to sink
                        SingleOutputStreamOperator<IncomingEvent> finalProcessedStream = processedStream
                                .map(new RichMapFunction<IncomingEvent, IncomingEvent>() {
                                        @Override
                                        public IncomingEvent map(IncomingEvent event) throws Exception {
                                                try {
                                                        // Additional processing could happen here
                                                        
                                                        // Log successful processing
                                                        LOG.info("Successfully processed event: account={}, ready to send to sink topic {}", 
                                                                event.getAccount(), sinkTopic);
                                                        return event;
                                                } catch (Exception e) {
                                                        LOG.error("Error in final processing stage: {} - {}", 
                                                                e.getClass().getName(), e.getMessage(), e);
                                                        throw e; // Re-throw to trigger Flink's error handling
                                                }
                                        }
                                });

                        // Send to Kafka sink with error handling
                        finalProcessedStream.sinkTo(kafkaSink);

                        env.execute("Kafka Streaming Job");
                        
                } catch (Exception e) {
                        LOG.error("Fatal error in Kafka Streaming Job: {} - {}", 
                                e.getClass().getName(), e.getMessage(), e);
                        throw e;
                }
        }
}
