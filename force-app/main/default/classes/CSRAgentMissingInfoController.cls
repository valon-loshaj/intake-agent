public with sharing class CSRAgentMissingInfoController {
    @InvocableMethod(label='Check Documents For Missing Information' 
                     description='Analyzes documents for missing mandatory information')
    public static List<List<ReceivedDocument>> checkDocumentsForMissingInformation(List<ReceivedDocument> documents) {
        validateInput(documents);
        checkUserAccess();

        List<ReceivedDocument> results = new List<ReceivedDocument>();
        for (ReceivedDocument doc : documents) {
            processDocument(doc);
            results.add(doc);
        }

        // Update the received documents with the new status and status reason
		validateCRUDPermissions();
        update results;

		// Wrap the results list in another list for Flow compatibility
        List<List<ReceivedDocument>> wrappedResults = new List<List<ReceivedDocument>>();
        wrappedResults.add(results);

        return wrappedResults;
    }

    private static void validateInput(List<ReceivedDocument> documents) {
        if (documents == null || documents.isEmpty()) {
            throw new IllegalArgumentException('Documents list cannot be null or empty.');
        }
    }

    private static void checkUserAccess() {
        if (!Schema.sObjectType.ReceivedDocument.isAccessible()) {
            throw new System.NoAccessException();
        }
    }

	private static void validateCRUDPermissions() {
		if (!Schema.sObjectType.ReceivedDocument.isUpdateable()) {
			throw new System.NoAccessException();
		}
	}

    private static void processDocument(ReceivedDocument doc) {
        if (doc.APS_OCR_Confidence_Score__c < 0.88) {
            doc.Status = 'Unusable';
            doc.StatusReason = 'Low OCR Confidence Score';
            return;
        }

        if (String.isNotBlank(doc.APS_OCR_JSON_Response__c)) {
            processOCRResponse(doc);
        }
    }

    private static void processOCRResponse(ReceivedDocument doc) {
        Map<String, Object> ocrData = (Map<String, Object>)JSON.deserializeUntyped(doc.APS_OCR_JSON_Response__c);
        Map<String, Object> patientInfo = (Map<String, Object>)ocrData.get('Patient Information');

        List<String> missingFields = new List<String>();

        if (patientInfo != null) {
            if (patientInfo.get('APS_First_Name__c') == null) {
                missingFields.add('First Name');
            }
            if (patientInfo.get('APS_Last_Name__c') == null) {
                missingFields.add('Last Name');
            }
            if (patientInfo.get('APS_DOB__c') == null) {
                missingFields.add('Date of Birth');
            }
        }

        if (!missingFields.isEmpty()) {
            doc.Status = 'Unusable';
            doc.StatusReason = 'Missing Mandatory Information: ' + String.join(missingFields, ', ');
        }
    }
}