package com.hackathon;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class IncomingEvent {

  private static final Logger LOG = LoggerFactory.getLogger(IncomingEvent.class);

  private String version;
  private String eventType;
  private String eventCreationTime;
  private String sourceDatasetName;
  private String sourcePartition;
  private String sourceOffset;
  private String account;
  private String payloadType;
  private Object payload;

  @JsonProperty("version")
  public String getVersion() {
    return version;
  }

  public void setVersion(String version) {
    this.version = version;
  }

  @JsonProperty("eventType")
  public String getEventType() {
    return eventType;
  }

  public void setEventType(String eventType) {
    this.eventType = eventType;
  }

  @JsonProperty("eventCreationTime")
  public String getEventCreationTime() {
    return eventCreationTime;
  }

  public void setEventCreationTime(String eventCreationTime) {
    this.eventCreationTime = eventCreationTime;
  }

  @JsonProperty("sourceDatasetName")
  public String getSourceDatasetName() {
    return sourceDatasetName;
  }

  public void setSourceDatasetName(String sourceDatasetName) {
    this.sourceDatasetName = sourceDatasetName;
  }

  @JsonProperty("sourcePartition")
  public String getSourcePartition() {
    return sourcePartition;
  }

  public void setSourcePartition(String sourcePartition) {
    this.sourcePartition = sourcePartition;
  }

  @JsonProperty("sourceOffset")
  public String getSourceOffset() {
    return sourceOffset;
  }

  public void setSourceOffset(String sourceOffset) {
    this.sourceOffset = sourceOffset;
  }

  @JsonProperty("account")
  public String getAccount() {
    return account;
  }

  public void setAccount(String account) {
    this.account = account;
  }

  @JsonProperty("payloadType")
  public String getPayloadType() {
    return payloadType;
  }

  public void setPayloadType(String payloadType) {
    this.payloadType = payloadType;
  }

  @JsonProperty("payload")
  public Object getPayload() {
    return payload;
  }

  public void setPayload(Object payload) {
    this.payload = payload;
  }

  // Parse the payload based on the payloadtype
  public Object parsePayload() throws IOException {
    ObjectMapper mapper = new ObjectMapper();
    Object parsedPayload = null;

    if ("TransactionEventPayload".equals(payloadType)) {
      parsedPayload = mapper.convertValue(payload, TransactionEventPayload.class);
    } else if ("AccountUpdateEventPayload".equals(payloadType)) {
      parsedPayload = mapper.convertValue(payload,
          AccountUpdateEventPayload.class);
    } else {
      throw new IllegalArgumentException("Unknown payload type: " + payloadType);
    }

    return parsedPayload;
  }

  @Override
  public String toString() {
    return "IncomingEvent{" +
        "version='" + version + '\'' +
        ", eventType='" + eventType + '\'' +
        ", eventCreationTime='" + eventCreationTime + '\'' +
        ", sourceDatasetName='" + sourceDatasetName + '\'' +
        ", sourcePartition='" + sourcePartition + '\'' +
        ", sourceOffset='" + sourceOffset + '\'' +
        ", account='" + account + '\'' +
        ", payloadType='" + payloadType + '\'' +
        ", payload=" + payload +
        '}';
  }
}
