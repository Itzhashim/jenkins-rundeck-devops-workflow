package com.devops.demo.controller;

import com.devops.demo.model.AppStatus;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
public class AppController {

    @Value("${app.name:DevOps Demo Application}")
    private String appName;

    @Value("${app.version:1.0.0}")
    private String appVersion;

    @Value("${app.environment:production}")
    private String environment;

    @GetMapping("/")
    public ResponseEntity<AppStatus> getRootStatus() {
        AppStatus status = new AppStatus(
                appName,
                appVersion,
                "UP",
                environment,
                "DevOps Demo Application is running"
        );
        return ResponseEntity.ok(status);
    }

    @GetMapping("/api/info")
    public ResponseEntity<Map<String, Object>> getAppInfo() {
        Map<String, Object> info = new HashMap<>();
        info.put("application", appName);
        info.put("version", appVersion);
        info.put("environment", environment);
        info.put("framework", "Spring Boot 3.3.4");
        info.put("ciTool", "Jenkins");
        info.put("opsTool", "Rundeck");
        info.put("maintainer", "DevOps Engineering Team");
        return ResponseEntity.ok(info);
    }
}
