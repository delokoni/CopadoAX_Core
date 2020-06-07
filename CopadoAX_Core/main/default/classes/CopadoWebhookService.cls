/**
 * Created by kheidt.
 */

public class CopadoWebhookService {

    public static HttpResponse callWebhook(String requestMethod, String url, String body){

        Http h = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod( requestMethod);
        request.setEndpoint(url);
        if(body != null){
            request.setBody(body);

            //if a body is provided, we set the content type to application/json. this is done in the
            request.setHeader('Content-Type','application/json');
        }

        HttpResponse response = h.send(request);
        return response;
    }
}