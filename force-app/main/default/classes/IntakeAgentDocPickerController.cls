public with sharing class IntakeAgentDocPickerController {
    @InvocableMethod(label='Get Received Documents Awaiting Review' description='Retrieves documents with a status of "Draft", sorted by CreatedDate in descending order, including OCR-related fields.')
    public static List<List<ReceivedDocument>> getReceivedDocumentsAwaitingReview(List<String> request) {
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

        // Wrap the receivedDocuments list in another list for Flow compatibility
        List<List<ReceivedDocument>> wrappedResults = new List<List<ReceivedDocument>>();
        wrappedResults.add(receivedDocuments);

        return wrappedResults;
    }
}