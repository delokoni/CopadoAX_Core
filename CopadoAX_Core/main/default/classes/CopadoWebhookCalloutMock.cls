/**
 * Created by kheidt.
 */
@isTest
public class CopadoWebhookCalloutMock implements HttpCalloutMock{

    public String responseBody;
    public String responseStatus;

    //method to modify response parameters for a specific case, to avoid multiple mock classes
    public void mockStaticCodeAnalysisCall(){

        //set response parameters to check in test class assert
        responseBody = '{"testResponse":"static code analysis is being run"}';
        responseStatus = '2018';
    }

    public void mockCreatePromotionAndDeployCall(){

        responseBody = '{"testResponse":"the promotion is being deployed"}';
        responseStatus = '2019';
    }

    //sfdc method for mocking the response
    public HttpResponse respond(HttpRequest req){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(responseBody);
        response.setStatus(responseStatus);
        return response;
    }
}