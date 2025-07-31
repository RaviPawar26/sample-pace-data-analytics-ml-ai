package com.hackathon;

public interface EventPayload {

  public String getProcessedJavaTime();

  public void setProcessedJavaTime(String processedJavaTime);

  public long getProductKey();

  public void setProductKey(long productKey);

  public IncomingEvent getIncomingEvent();

  public void setIncomingEvent(IncomingEvent incomingEvent);
}
