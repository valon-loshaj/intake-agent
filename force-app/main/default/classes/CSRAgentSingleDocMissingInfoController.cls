public with sharing class CSRAgentSingleDocMissingInfoController {
    
    // Input wrapper class
    public class SingleDocumentRequest {
        @InvocableVariable(required=true label='Document ID' description='ID of the document to analyze')
        public String documentId;
        
        @InvocableVariable(required=false label='Minimum OCR Score' description='Minimum acceptable OCR confidence score')
        public Decimal minimumOCRScore = 0.88;
    }

    // Output wrapper class
    public class SingleDocumentResult {
        @InvocableVariable(label='Document Status' description='Updated status of the document')
        public String status;
        
        @InvocableVariable(label='Status Reason' description='Reason for the status update')
        public String statusReason;
    }

    @InvocableMethod(label='Check Single Document For Missing Information' 
                     description='Analyzes a single document for missing mandatory information')
    public static List<SingleDocumentResult> checkSingleDocumentForMissingInformation(List<SingleDocumentRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Request list cannot be null or empty.');
        }

        // Get first request since we only process one document
        SingleDocumentRequest request = requests[0];
        if (request == null || String.isBlank(request.documentId)) {
            throw new IllegalArgumentException('Document ID cannot be null or empty.');
        }

        checkUserAccess();
        validateCRUDPermissions();

        // Query single document
        List<ReceivedDocument> docs = [
            SELECT Id, Status, StatusReason, APS_OCR_Confidence_Score__c, 
                   APS_OCR_JSON_Response__c
            FROM ReceivedDocument 
            WHERE Id = :request.documentId
            LIMIT 1
        ];

        if (docs.isEmpty()) {
            throw new IllegalArgumentException('Document not found with ID: ' + request.documentId);
        }

        // Process document
        ReceivedDocument doc = docs[0];
        processDocument(doc, request.minimumOCRScore);

        // Single update outside of any loops
        update doc;

        // Create result and wrap in List
        SingleDocumentResult result = new SingleDocumentResult();
        result.status = doc.Status;
        result.statusReason = doc.StatusReason;
        
        return new List<SingleDocumentResult>{result};
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