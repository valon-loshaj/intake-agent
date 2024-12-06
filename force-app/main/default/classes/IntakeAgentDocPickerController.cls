public with sharing class IntakeAgentDocPickerController {
    
    // Output wrapper class for consistent response handling
    public class DocumentPickerResult {
        @InvocableVariable(label='Available Documents' description='List of received documents awaiting review')
        public List<ReceivedDocument> availableDocuments;
    }

    @InvocableMethod(label='Get Received Documents Awaiting Review' 
                     description='Retrieves documents with a status of "Draft", sorted by CreatedDate in descending order, including OCR-related fields.')
    public static List<DocumentPickerResult> getReceivedDocumentsAwaitingReview(List<String> request) {
        // Validate the input if necessary
        if (request == null || request.isEmpty()) {
            throw new IllegalArgumentException('Request input cannot be null or empty.');
        }

        // Check if the user has read access to ReceivedDocument
        if (!Schema.sObjectType.ReceivedDocument.isAccessible()) {
            throw new System.NoAccessException();
        }

        // Query ReceivedDocument records with relevant fields
        List<ReceivedDocument> receivedDocuments = [
            SELECT Id, Name, Status, CreatedDate, 
                   APS_OCR_Confidence_Score__c, APS_OCR_Response_Status__c, APS_OCR_JSON_Response__c
            FROM ReceivedDocument
            WHERE Status = 'Draft'
            ORDER BY CreatedDate DESC
        ];

        // Create and populate the result wrapper
        DocumentPickerResult result = new DocumentPickerResult();
        result.availableDocuments = receivedDocuments;
        
        // Wrap the result in a list for Flow compatibility
        List<DocumentPickerResult> results = new List<DocumentPickerResult>();
        results.add(result);

        return results;
    }
}