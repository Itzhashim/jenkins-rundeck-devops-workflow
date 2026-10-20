package com.devops.demo.model;

import java.time.Instant;

public class AppStatus {
    private String application;
    private String version;
    private String status;
    private String environment;
    private String message;
    private Instant timestamp;

    public AppStatus() {
        this.timestamp = Instant.now();
    }

    public AppStatus(String application, String version, String status, String environment, String message) {
        this.application = application;
        this.version = version;
        this.status = status;
        this.environment = environment;
        this.message = message;
        this.timestamp = Instant.now();
    }

    public String getApplication() {
        return application;
    }

    public void setApplication(String application) {
        this.application = application;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getEnvironment() {
        return environment;
    }

    public void setEnvironment(String environment) {
        this.environment = environment;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Instant getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Instant timestamp) {
        this.timestamp = timestamp;
    }
}
