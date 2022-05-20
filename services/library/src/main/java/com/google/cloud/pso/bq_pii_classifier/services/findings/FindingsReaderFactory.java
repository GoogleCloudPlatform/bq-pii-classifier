package com.google.cloud.pso.bq_pii_classifier.services.findings;

import com.google.cloud.pso.bq_pii_classifier.services.bq.BigQueryService;

public class FindingsReaderFactory {

    public static FindingsReaderType findReader(
            boolean isAutoDlp,
            boolean promoteMixedPiiTypes
    ){
        if (isAutoDlp){
            return FindingsReaderType.AUTO_DLP;
        }else{
            if(promoteMixedPiiTypes){
                return FindingsReaderType.STANDARD_DLP_WITH_MIXED_INFO_TYPES_PROMOTION;
            }else{
                return FindingsReaderType.STANDARD_DLP_WITHOUT_MIXED_INFO_TYPES_PROMOTION;
            }
        }
    }

    public static FindingsReader getNewReader(
            FindingsReaderType readerType,
            BigQueryService bqService,
            String dlpProject,
            String dlpDataset,
            String dlpTable,
            String datasetDomainMapView,
            String projectDomainMapView,
            String infoTypesPolicyTagsMapView
    ) {

        switch (readerType){
            case AUTO_DLP:
                return new FindingsReaderAutoDlp(
                    bqService,
                    dlpProject,
                    dlpDataset,
                    dlpTable,
                    datasetDomainMapView,
                    projectDomainMapView,
                    infoTypesPolicyTagsMapView
            );
            case STANDARD_DLP_WITH_MIXED_INFO_TYPES_PROMOTION:
                return new FindingsReaderStandardDlp(
                        bqService,
                        dlpProject,
                        dlpDataset,
                        dlpTable,
                        datasetDomainMapView,
                        projectDomainMapView,
                        infoTypesPolicyTagsMapView,
                        "sql/v_dlp_fields_findings_with_promotion.tpl"
                );
            case STANDARD_DLP_WITHOUT_MIXED_INFO_TYPES_PROMOTION:
                return new FindingsReaderStandardDlp(
                        bqService,
                        dlpProject,
                        dlpDataset,
                        dlpTable,
                        datasetDomainMapView,
                        projectDomainMapView,
                        infoTypesPolicyTagsMapView,
                        "sql/v_dlp_fields_findings_without_promotion.tpl"
                );
            default: throw new java.lang.UnsupportedOperationException(
                    String.format("FindingsReader %s is not supported", readerType)
            );
        }


    }
}
