public with sharing class CSRAgentCheckDocumentIDs {
    
    // Input wrapper class
    public class DocumentIDRequest {
        @InvocableVariable(required=true label='Documents to Process' description='List of received documents to extract IDs from')
        public List<ReceivedDocument> documentsToProcess;
    }

    // Output wrapper class
    public class DocumentIDResult {
        @InvocableVariable(label='Document IDs' description='List of extracted document IDs')
        public List<String> documentIds;
    }

    @InvocableMethod(label='Extract Document IDs' 
                     description='Extracts IDs from a list of received documents')
    public static List<DocumentIDResult> extractDocumentIDs(List<DocumentIDRequest> requests) {
        List<DocumentIDResult> results = new List<DocumentIDResult>();
        
        for (DocumentIDRequest request : requests) {
            validateInput(request.documentsToProcess);
            checkUserAccess();

            List<String> docIds = new List<String>();
            for (ReceivedDocument doc : request.documentsToProcess) {
                docIds.add(doc.Id);
            }

            DocumentIDResult result = new DocumentIDResult();
            result.documentIds = docIds;
            results.add(result);
        }

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
}