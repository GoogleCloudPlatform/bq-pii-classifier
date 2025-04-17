package com.google.cloud.pso.bq_pii_classifier.apps;

import com.google.cloud.pso.bq_pii_classifier.apps.dispatcher.BigQueryDispatcher;
import com.google.cloud.pso.bq_pii_classifier.apps.bq_tagger.BigQueryTaggerController;
import com.google.cloud.pso.bq_pii_classifier.apps.dispatcher.GcsDispatcher;
import com.google.cloud.pso.bq_pii_classifier.apps.gcs_tagger.GcsTaggerController;

public class EntryPoint {
  public static void main(String[] args) throws Exception {

    switch (args[0].toLowerCase()) {
      case "bq-dispatcher" -> BigQueryDispatcher.main(args);
      case "bq-tagger" -> BigQueryTaggerController.main(new String[0]);
      case "gcs-dispatcher" -> GcsDispatcher.main(args);
      case "gcs-tagger" -> GcsTaggerController.main(new String[0]);
      default -> throw new Exception(
          String.format("Provided entry point is not supported: %s", args[0].toLowerCase()));
    }
  }
}
