package com.google.cloud.pso.bq_pii_classifier.entities;

import com.google.gson.Gson;
import java.util.List;
import java.util.Map;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;

public record InfoTypeInfo(String classification, List<ResourceLabel> labels) {

    public static Map<String, InfoTypeInfo> fromJsonMap(String jsonStr){
        Gson gson = new Gson();
        Type mapType = new TypeToken<Map<String, InfoTypeInfo>>(){}.getType();
        return gson.fromJson(jsonStr, mapType);
    }
}
