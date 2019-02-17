import ballerina/http;
import ballerina/test;
import ballerina/config;
import ballerina/io;

string env = config:getAsString("ENV", default = "Dev");
string eiEP = config:getAsString(env +"_EI_SERVICE", default = "http://localhost:8280");
http:Client healthAPIEP  = new(eiEP + "/healthcare");
int currentApptNumber = -1;

@test:BeforeEach
function beforeEachTest() { 
    currentApptNumber = -1;
}

@test:Config {
    dataProvider: "surgery_reserve_same_doctor_appointments_data_gen"
}
function surgery_reserve_same_doctor_appointments_test(json aReq, json aRes) returns error?{
    
    // Send a 'post' request and obtain the response
    http:Response | error res =  healthAPIEP -> post("/categories/surgery/reserve", aReq);
    if (res is error) {
        test:assertFail(msg = "Error: "+ res.reason());
        return;
    } else {
        http:Response response = res;
        // assert the status code
        test:assertEquals(res.statusCode, 200, msg="Unexpected status code!");

        // assert the payload
        json payload = check res.getJsonPayload();
        if (currentApptNumber == -1) {
            currentApptNumber = untaint check int.convert(payload.appointmentNo);
        } else {
            // test the appointment number
            currentApptNumber = currentApptNumber + 1;
            test:assertEquals(payload.appointmentNo, currentApptNumber, 
            msg = "Appointment numbers are not generated correctly!");
        }

        json doctorName = payload.doctorName;
        test:assertEquals(doctorName, aRes.doctorName, msg = "Doctor's name doesn't match!");

        test:assertEquals(payload.patient, aRes.patient, msg = "Patient's name isn't correct!");

        // test the discount
        float price = check float.convert(payload.actualFee);
        int discount = check int.convert(payload.discount);
        float actualPrice = check float.convert(payload.discounted);
        test:assertEquals(actualPrice, price * (100 - discount)/100, msg ="Discount calculation wrong!");
        
        // test the status
        test:assertEquals(payload.status, aRes.status, msg = "Status is not correct!");

    }
}

// test data
function surgery_reserve_same_doctor_appointments_data_gen() returns(json[][]) {
    return [
    [{
            "name": "John Doe",
            "dob": "1940-03-19",
            "ssn": "234-23-525",
            "address": "California",
            "phone": "8770586755",
            "email": "johndoe@gmail.com",
            "doctor": "thomas collins",
            "hospital": "grand oak community hospital",
            "cardNo": "7844481124110331",
            "appointment_date": "2025-04-02"
    }, {
            "appointmentNo": 1,
            "doctorName": "thomas collins",
            "patient": "John Doe",
            "actualFee": 7000.0,
            "discount": 20,
            "discounted": 5600.0,
            "paymentID": "480fead2-e592-4791-941a-690ad1363802",
            "status": "Settled"
    }],
    [{
            "name": "Mark Hex",
            "dob": "1980-08-05",
            "ssn": "432-23-111",
            "address": "NewYork",
            "phone": "99999999",
            "email": "mark@gmail.com",
            "doctor": "thomas collins",
            "hospital": "grand oak community hospital",
            "cardNo": "4122244400022244",
            "appointment_date": "2025-04-02"
    }, {
            "appointmentNo": 2,
            "doctorName": "thomas collins",
            "patient": "Mark Hex",
            "actualFee": 7000.0,
            "discount": 20,
            "discounted": 5600.0,
            "paymentID": "99999992-e592-4791-941a-690ad1363802",
            "status": "Settled"
    }]
    ];
}
