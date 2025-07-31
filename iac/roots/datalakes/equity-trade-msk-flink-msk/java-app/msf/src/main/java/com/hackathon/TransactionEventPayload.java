package com.hackathon;

import com.fasterxml.jackson.annotation.JsonProperty;

public class TransactionEventPayload implements EventPayload {

  private String id;
  private String transactionSourceName;
  private String sourceTransactionId;
  private String sourceTransactionEntryTime;
  private String accountNumber;
  private String security;
  private String transactionType;
  private String transactionEventType;
  private String tradeDate;
  private String settleDate;
  private String settleCurrency;
  private Double tradeQuantity;
  private Double settleAmount;
  private String processedJavaTime;
  private long productKey;
  private IncomingEvent incomingEvent;

  @JsonProperty("id")
  public String getId() {
    return id;
  }

  public void setId(String id) {
    this.id = id;
  }

  @JsonProperty("transactionSourceName")
  public String getTransactionSourceName() {
    return transactionSourceName;
  }

  public void setTransactionSourceName(String transactionSourceName) {
    this.transactionSourceName = transactionSourceName;
  }

  @JsonProperty("sourceTransactionId")
  public String getSourceTransactionId() {
    return sourceTransactionId;
  }

  public void setSourceTransactionId(String sourceTransactionId) {
    this.sourceTransactionId = sourceTransactionId;
  }

  @JsonProperty("sourceTransactionEntryTime")
  public String getSourceTransactionEntryTime() {
    return sourceTransactionEntryTime;
  }

  public void setSourceTransactionEntryTime(String sourceTransactionEntryTime) {
    this.sourceTransactionEntryTime = sourceTransactionEntryTime;
  }

  @JsonProperty("accountNumber")
  public String getAccountNumber() {
    return accountNumber;
  }

  public void setAccountNumber(String accountNumber) {
    this.accountNumber = accountNumber;
  }

  @JsonProperty("security")
  public String getSecurity() {
    return security;
  }

  public void setSecurity(String security) {
    this.security = security;
  }

  @JsonProperty("transactionType")
  public String getTransactionType() {
    return transactionType;
  }

  public void setTransactionType(String transactionType) {
    this.transactionType = transactionType;
  }

  @JsonProperty("transactionEventType")
  public String getTransactionEventType() {
    return transactionEventType;
  }

  public void setTransactionEventType(String transactionEventType) {
    this.transactionEventType = transactionEventType;
  }

  @JsonProperty("tradeDate")
  public String getTradeDate() {
    return tradeDate;
  }

  public void setTradeDate(String tradeDate) {
    this.tradeDate = tradeDate;
  }

  @JsonProperty("settleDate")
  public String getSettleDate() {
    return settleDate;
  }

  public void setSettleDate(String settleDate) {
    this.settleDate = settleDate;
  }

  @JsonProperty("settleCurrency")
  public String getSettleCurrency() {
    return settleCurrency;
  }

  public void setSettleCurrency(String settleCurrency) {
    this.settleCurrency = settleCurrency;
  }

  @JsonProperty("tradeQuantity")
  public Double getTradeQuantity() {
    return tradeQuantity;
  }

  public void setTradeQuantity(Double tradeQuantity) {
    this.tradeQuantity = tradeQuantity;
  }

  @JsonProperty("settleAmount")
  public Double getSettleAmount() {
    return settleAmount;
  }

  public void setSettleAmount(Double settleAmount) {
    this.settleAmount = settleAmount;
  }

  @JsonProperty("ProcessedJavaTime")
  public String getProcessedJavaTime() {
    return processedJavaTime;
  }

  public void setProcessedJavaTime(String processedJavaTime) {
    this.processedJavaTime = processedJavaTime;
  }

  public long getProductKey() {
    return productKey;
  }

  public void setProductKey(long productKey) {
    this.productKey = productKey;
  }

  public IncomingEvent getIncomingEvent() {
    return incomingEvent;
  }

  public void setIncomingEvent(IncomingEvent incomingEvent) {
    this.incomingEvent = incomingEvent;
  }

  @Override
  public String toString() {

    return "{" +
        "\"eventType\":\"Transaction\"" +
        ", \"id\":\"" + id + '\"' +
        ", \"transactionSourceName\":\"" + transactionSourceName + '\"' +
        ", \"sourceTransactionId\":\"" + sourceTransactionId + '\"' +
        ", \"sourceTransactionEntryTime:\"" + sourceTransactionEntryTime + '\"' +
        ", \"accountNumber\":\"" + accountNumber + '\"' +
        ", \"security\":\"" + security + '\"' +
        ", \"transactionType\":\"" + transactionType + '\"' +
        ", \"transactionEventType\":\"" + transactionEventType + '\"' +
        ", \"tradeDate\":\"" + tradeDate + '\"' +
        ", \"settleDate\":\"" + settleDate + '\"' +
        ", \"settleCurrency\":\"" + settleCurrency + '\"' +
        ", \"tradeQuantity:\"" + tradeQuantity + '\"' +
        ", \"settleAmount\":\"" + settleAmount + '\"' +
        ", \"processedJavaTime\":\"" + processedJavaTime + '\"' +
        ", \"productKey\":\"" + productKey + '\"' +
        "}";
  }
}
