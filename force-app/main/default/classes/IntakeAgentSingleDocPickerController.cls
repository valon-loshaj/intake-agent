public with sharing class IntakeAgentSingleDocPickerController {
    
    // Output wrapper class for consistent response handling
    public class SingleDocumentResult {
        @InvocableVariable(label='Document ID' description='ID of the first available document awaiting review')
        public String documentId;
    }

    @InvocableMethod(label='Get First Received Document Awaiting Review' 
                     description='Retrieves the first document with a status of "Draft", sorted by CreatedDate in descending order.')
    public static List<SingleDocumentResult> getFirstReceivedDocumentAwaitingReview(List<String> request) {
        // Validate the input if necessary
        if (request == null || request.isEmpty()) {
            throw new IllegalArgumentException('Request input cannot be null or empty.');
        }

        // Check if the user has read access to ReceivedDocument
        if (!Schema.sObjectType.ReceivedDocument.isAccessible()) {
            throw new System.NoAccessException();
        }

        // Query ReceivedDocument records with relevant fields, limit to 1
        List<ReceivedDocument> receivedDocuments = [
            SELECT Id
            FROM ReceivedDocument
            WHERE Status = 'Draft'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        // Create and populate the result wrapper
        SingleDocumentResult result = new SingleDocumentResult();
        result.documentId = !receivedDocuments.isEmpty() ? receivedDocuments[0].Id : null;
        
        // Wrap the result in a list for Flow compatibility
        List<SingleDocumentResult> results = new List<SingleDocumentResult>();
        results.add(result);

        return results;
    }
}