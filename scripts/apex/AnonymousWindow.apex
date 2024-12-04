List<String> request = new List<String>();
request.add('dummyRequest');

try {
    List<List<IntakeAgentDocPickerController.ReceivedDocumentDTO>> results = IntakeAgentDocPickerController.getReceivedDocumentsAwaitingReview(request);
    System.debug('Results wrapper size: ' + results.size());
    System.debug('Number of records: ' + (results.isEmpty() ? 0 : results[0].size()));
    System.debug('Results: ' + results);
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}
