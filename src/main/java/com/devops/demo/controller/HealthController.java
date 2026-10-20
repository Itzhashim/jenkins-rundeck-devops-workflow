package com.devops.demo.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.lang.management.ManagementFactory;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class HealthController {

    private final long startTime = System.currentTimeMillis();
    private volatile boolean simulatedFailure = false;

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> getHealth() {
        Map<String, Object> health = new HashMap<>();
        health.put("timestamp", Instant.now().toString());
        health.put("uptimeSeconds", (System.currentTimeMillis() - startTime) / 1000);

        if (simulatedFailure) {
            health.put("status", "UNHEALTHY");
            health.put("message", "Simulated degradation triggered for failure testing demo");
            return ResponseEntity.status(503).body(health);
        }

        health.put("status", "HEALTHY");
        health.put("service", "devops-demo-app");
        health.put("jvmUptimeMs", ManagementFactory.getRuntimeMXBean().getUptime());

        Map<String, String> components = new HashMap<>();
        components.put("webServer", "UP");
        components.put("memory", "OK");
        components.put("disk", "OK");
        health.put("components", components);

        return ResponseEntity.ok(health);
    }

    /**
     * Endpoint to simulate failure for testing Rundeck health-check failure alerts and recovery.
     * Can be toggled: /api/health/simulate?fail=true or ?fail=false
     */
    @GetMapping("/health/simulate")
    public ResponseEntity<Map<String, Object>> simulateFailure(@RequestParam(name = "fail", defaultValue = "true") boolean fail) {
        this.simulatedFailure = fail;
        Map<String, Object> response = new HashMap<>();
        response.put("simulatedFailureActive", this.simulatedFailure);
        response.put("message", fail ? "Application marked as UNHEALTHY for testing" : "Application restored to HEALTHY");
        return ResponseEntity.ok(response);
    }
}
