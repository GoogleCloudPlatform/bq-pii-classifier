package com.google.cloud.pso.bq_pii_classifier.entities;

import com.google.gson.Gson;
import java.util.List;
import java.util.Map;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;

public class InfoTypeInfo {

    private String classification;
    private List<String> labels;

    public InfoTypeInfo(String classification, List<String> labels) {
        this.classification = classification;
        this.labels = labels;
    }

    public String getClassification() {
        return classification;
    }

    public List<String> getLabels() {
        return labels;
    }

    @Override
    public String toString() {
        return "InfoTypeInfo{" +
                "classification='" + classification + '\'' +
                ", labels=" + labels +
                '}';
    }

    public static Map<String, InfoTypeInfo> fromJsonMap(String jsonStr){
        Gson gson = new Gson();
        Type mapType = new TypeToken<Map<String, InfoTypeInfo>>(){}.getType();
        return gson.fromJson(jsonStr, mapType);
    }
}
