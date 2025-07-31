package com.hackathon;

import com.fasterxml.jackson.annotation.JsonProperty;

public class AccountUpdateEventPayload implements EventPayload {

  private String account;
  private String businessDate;
  private String accountUpdateId;
  private Integer positionCount;
  private Integer transactionCount;
  private String sourceDatasetName;
  private String processedJavaTime;
  private long productKey;
  private IncomingEvent incomingEvent;

  @JsonProperty("account")
  public String getAccount() {
    return account;
  }

  public void setAccount(String account) {
    this.account = account;
  }

  @JsonProperty("businessDate")
  public String getBusinessDate() {
    return businessDate;
  }

  public void setBusinessDate(String businessDate) {
    this.businessDate = businessDate;
  }

  @JsonProperty("accountUpdateId")
  public String getAccountUpdateId() {
    return accountUpdateId;
  }

  public void setAccountUpdateId(String accountUpdateId) {
    this.accountUpdateId = accountUpdateId;
  }

  @JsonProperty("positionCount")
  public Integer getPositionCount() {
    return positionCount;
  }

  public void setPositionCount(Integer positionCount) {
    this.positionCount = positionCount;
  }

  @JsonProperty("transactionCount")
  public Integer getTransactionCount() {
    return transactionCount;
  }

  public void setTransactionCount(Integer transactionCount) {
    this.transactionCount = transactionCount;
  }

  @JsonProperty("sourceDatasetName")
  public String getSourceDatasetName() {
    return sourceDatasetName;
  }

  public void setSourceDatasetName(String sourceDatasetName) {
    this.sourceDatasetName = sourceDatasetName;
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
        "\"eventType\":\"AccountUpdateAvailable\"" +
        ", \"account\":\"" + account + '\"' +
        ", \"businessDate\":\"" + businessDate + '\"' +
        ", \"accountUpdateId\":\"" + accountUpdateId + '\"' +
        ", \"positionCount:\"" + positionCount + '\"' +
        ", \"transactionCount\":\"" + transactionCount + '\"' +
        ", \"sourceDatasetName\":\"" + sourceDatasetName + '\"' +
        ", \"processedJavaTime\":\"" + processedJavaTime + '\"' +
        ", \"productKey\":\"" + productKey + '\"' +
        "}";
  }
}