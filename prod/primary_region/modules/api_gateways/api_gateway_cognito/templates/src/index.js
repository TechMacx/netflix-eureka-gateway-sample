// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

const aws = require("aws-sdk");
const ses = new aws.SES({ region: "us-east-2" });


const getPoolDetails = (poolId) => {

    const prodWhiteList = ['animesh.kumar@arpiantech.com', 'animesh.kumar@gometapixel.com'];

    // for UAT whitlist add/remove email id bellow
    const uatWhiteList = ['anil.sharma@arpiantech.com', 'animesh.kumar@gometapixel.com', 'animesh.kumar@arpiantech.com' ];

    const poolDetails = {
        "us-east-1_waESM5mrn": {
            env: "PROD",
            application: "Admin Portal for PROD",
            whitelisting: [...prodWhiteList]
        },
        "us-east-1_vo6NrVRw3": {
            env: "UAT",
            application: "Admin Portal for UAT",
            whitelisting: [...uatWhiteList]
        }
    };
    return poolDetails[poolId] ? poolDetails[poolId] : null;
};

// for PROD whitlist add/remove email id bellow

exports.handler = async function (event, context, callback) {


    try {
        const poolDetails = getPoolDetails(event?.userPoolId);
        if (!poolDetails) {
            throw new Error("Pool details not found");
        }
        const { env, application, whitelisting } = poolDetails;
        const loggedInUserEmail = event.request?.userAttributes?.email;



        let toAddressList = ["MetaPixelAlerts@arpiantech.com"];

        if (!whitelisting.includes(loggedInUserEmail.toLowerCase())) {
            toAddressList.push('animesh.kumar@arpiantech.com');
            toAddressList.push('manish.agrawal@arpiantech.com');
        }

        const params = {
            Destination: {
                ToAddresses: toAddressList,
            },
            Message: {
                Body: {

                    Html: {
                        Data: `<html><body>
                        <table summary="Login Details" border>
                            <caption> <h1>Login Details</h1></caption>
                            <thead class="aural if not needed">
                                <tr><th scope="col">keys</th><th scope="col">values</th></tr>
                            </thead>
                            <tbody class="group1">  
                                <tr><th scope="row">Environment</th><td>${env}</td></tr>
                                <tr><th scope="row">Application</th><td>${application}</td></tr>
                                <tr><th scope="row">Pool Id</th><td>${event?.userPoolId}</td></tr>
                            </tbody>
                            <tbody class="group2">
                                <tr><th scope="row">User Name</th><td>${event.userName}</td></tr>
                                <tr><th scope="row">User Email</th><td>${event.request?.userAttributes?.email}</td></tr>
                                <tr><th scope="row">Is New Device</th><td>${event.request?.newDeviceUsed ? 'Yes' : 'No'}</td></tr>
                            </tbody>
                        </table>
                        <br/>
                        <h2>Full Details</h2>
                        <pre>${JSON.stringify(event, null, 2)}</pre></body></html>`
                    }
                },

                Subject: { Data: `${application} : User Login Alert for ${loggedInUserEmail}` },
            },
            Source: "MetaPixelAlerts@arpiantech.com",
        };

        await ses.sendEmail(params).promise();
        callback(null, event);
    } catch (error) {
        const params = {
            Destination: {
                ToAddresses: ["manish.agrawal@arpiantech.com","animesh.kumar@arpiantech.com"],
            },
            Message: {
                Body: {
                    Text: {
                        Charset: "UTF-8",
                        Data: `${error}`
                    }
                },
                Subject: { Data: `Issue with Login Lambda` },
            },
            Source: "MetaPixelAlerts@arpiantech.com",
        };
        ses.sendEmail(params).promise();
        callback(null, event);
    }
};
