public with sharing class CSRAgentMissingInfoController {
    
    // Input wrapper class for the invocable method
    public class DocumentAnalysisRequest {
        @InvocableVariable(required=true label='Documents to Analyze' description='List of received documents that need analysis')
        public List<ReceivedDocument> documentsToAnalyze;
        
        @InvocableVariable(required=false label='Minimum OCR Score' description='Minimum acceptable OCR confidence score')
        public Decimal minimumOCRScore = 0.88;
    }

    // Output wrapper class for consistent response handling
    public class DocumentAnalysisResult {
        @InvocableVariable(label='Processed Documents' description='Documents after analysis with updated status')
        public List<ReceivedDocument> processedDocuments;
    }

    @InvocableMethod(label='Check Documents For Missing Information' 
                     description='Analyzes documents for missing mandatory information')
    public static List<DocumentAnalysisResult> checkDocumentsForMissingInformation(List<DocumentAnalysisRequest> requests) {
        List<DocumentAnalysisResult> results = new List<DocumentAnalysisResult>();
        
		List<ReceivedDocument> processedDocs = new List<ReceivedDocument>();
		for (DocumentAnalysisRequest request : requests) {
            validateInput(request.documentsToAnalyze);
            checkUserAccess();

            for (ReceivedDocument doc : request.documentsToAnalyze) {
                processDocument(doc, request.minimumOCRScore);
                processedDocs.add(doc);
            }

            validateCRUDPermissions();

            DocumentAnalysisResult result = new DocumentAnalysisResult();
            result.processedDocuments = processedDocs;
            results.add(result);
        }

		validateCRUDPermissions();
		update processedDocs;
        return results;
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

    // Update the processDocument method to accept OCR threshold
    private static void processDocument(ReceivedDocument doc, Decimal minimumOCRScore) {
        if (doc.APS_OCR_Confidence_Score__c < minimumOCRScore) {
            doc.Status = 'Unusable';
            doc.StatusReason = 'Low OCR Confidence Score';
            return;
        }

        if (String.isNotBlank(doc.APS_OCR_JSON_Response__c)) {
            processOCRResponse(doc);
        }
    }

    private static void processOCRResponse(ReceivedDocument doc) {
        try {
            Map<String, Object> ocrData = (Map<String, Object>)JSON.deserializeUntyped(doc.APS_OCR_JSON_Response__c);
            List<Object> patientInfoList = (List<Object>)ocrData.get('Patient Information');
            
            if (patientInfoList == null) {
                doc.Status = 'Unusable';
                doc.StatusReason = 'Missing Patient Information section';
                return;
            }

            // Initialize variables to store found values
            String firstName = null;
            String lastName = null;
            String dob = null;

            // Loop through the list of patient information objects
            for (Object item : patientInfoList) {
                Map<String, Object> fieldMap = (Map<String, Object>)item;
                if (fieldMap.containsKey('APS_First_Name__c')) {
                    firstName = (String)fieldMap.get('APS_First_Name__c');
                }
                if (fieldMap.containsKey('APS_Last_Name__c')) {
                    lastName = (String)fieldMap.get('APS_Last_Name__c');
                }
                if (fieldMap.containsKey('APS_DOB__c')) {
                    dob = (String)fieldMap.get('APS_DOB__c');
                }
            }

            // Check for missing fields
            List<String> missingFields = new List<String>();
            if (firstName == null) {
                missingFields.add('First Name');
            }
            if (lastName == null) {
                missingFields.add('Last Name');
            }
            if (dob == null) {
                missingFields.add('Date of Birth');
            }

            if (!missingFields.isEmpty()) {
                doc.Status = 'Unusable';
                doc.StatusReason = 'Missing Mandatory Information: ' + String.join(missingFields, ', ');
            }
        } catch (Exception e) {
            doc.Status = 'Unusable';
            doc.StatusReason = 'Error processing OCR data: ' + e.getMessage();
        }
    }
}