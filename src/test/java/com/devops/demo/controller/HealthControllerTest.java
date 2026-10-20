package com.devops.demo.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class HealthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testHealthEndpointReturnsHealthyByDefault() throws Exception {
        mockMvc.perform(get("/api/health").contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("HEALTHY"))
                .andExpect(jsonPath("$.service").value("devops-demo-app"))
                .andExpect(jsonPath("$.components.webServer").value("UP"));
    }

    @Test
    void testSimulatedFailureToggle() throws Exception {
        // Trigger simulated failure
        mockMvc.perform(get("/api/health/simulate?fail=true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.simulatedFailureActive").value(true));

        // Verify health endpoint now reports 503 Service Unavailable & UNHEALTHY
        mockMvc.perform(get("/api/health"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.status").value("UNHEALTHY"));

        // Reset failure back to healthy
        mockMvc.perform(get("/api/health/simulate?fail=false"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.simulatedFailureActive").value(false));

        // Verify health endpoint is back to 200 OK
        mockMvc.perform(get("/api/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("HEALTHY"));
    }
}
