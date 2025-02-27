package com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.gcs;

import com.google.cloud.batch.v1.*;
import com.google.cloud.batch.v1.AllocationPolicy.InstancePolicy;
import com.google.cloud.batch.v1.AllocationPolicy.InstancePolicyOrTemplate;
import com.google.cloud.batch.v1.LogsPolicy.Destination;
import com.google.cloud.batch.v1.Runnable;
import com.google.cloud.batch.v1.Runnable.Container;
import com.google.protobuf.Duration;

import java.io.FileDescriptor;
import java.io.IOException;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class CloudBatchTest {

    public static void main(String[] args)
            throws IOException, ExecutionException, InterruptedException, TimeoutException {
        // TODO(developer): Replace these variables before running the sample.
        // Project ID or project number of the Cloud project you want to use.
        String projectId = "bqsc-host-v1";

        // Name of the region you want to use to run the job. Regions that are
        // available for Batch are listed on: https://cloud.google.com/batch/docs/get-started#locations
        String region = "europe-west3";

        // The name of the job that will be created.
        // It needs to be unique for each project and region pair.
        String jobName = "pubsub-publish-"+ UUID.randomUUID();

        createContainerJob(projectId, region, jobName);
    }

    // This method shows how to create a sample Batch Job that will run a simple command inside a
    // container on Cloud Compute instances.
    public static void createContainerJob(String projectId, String region, String jobName)
            throws IOException, ExecutionException, InterruptedException, TimeoutException {
        // Initialize client that will be used to send requests. This client only needs to be created
        // once, and can be reused for multiple requests. After completing all of your requests, call
        // the `batchServiceClient.close()` method on the client to safely
        // clean up any remaining background resources.
        try (BatchServiceClient batchServiceClient = BatchServiceClient.create()) {

            // Define what will be done as part of the job.
            Runnable runnable =
                    Runnable.newBuilder()
                            .setContainer(
                                    Container.newBuilder()
                                            .setImageUri("europe-west3-docker.pkg.dev/bqsc-host-v1/docker-repo/pubsub-publisher-testing:latest")
                                            //.setEntrypoint("java -cp target/bq-pii-classifier-library-2.0.0-jar-with-dependencies.jar com.google.cloud.pso.bq_pii_classifier.functions.dispatcher.gcs.PubSubStressTesting")
                                            .addCommands("10000") // 100000 100000000 5 100 1000000 1
                                            .addCommands("5000000")
                                            .addCommands("5")
                                            .addCommands("100")
                                            .addCommands("1000000")
                                            .addCommands("1")
                                            .build())
                            .build();

            // We can specify what resources are requested by each task.
            ComputeResource computeResource =
                    ComputeResource.newBuilder()
                            // In milliseconds per cpu-second
                            .setCpuMilli(32*1000) // full cpu resources of the machine
                            // In MiB.
                            .setMemoryMib(32*1000) // full mem resources of the machine
                            .build();

            Environment environment = Environment.newBuilder()
                    .putVariables("TEST_VARIABLE", "test-variable-value")
                    .build();

            TaskSpec task =
                    TaskSpec.newBuilder()
                            // Jobs can be divided into tasks. In this case, we have only one task.
                            .addRunnables(runnable)
                            .setComputeResource(computeResource) // When this is not set, defaults to 2 cpus and 1.95GB
                            .setMaxRetryCount(0)
                            .setEnvironment(environment)
                            //.setMaxRunDuration(Duration.newBuilder().setSeconds(3600).build())
                            .build();

            // Tasks are grouped inside a job using TaskGroups.
            // Currently, it's possible to have only one task group.
            TaskGroup taskGroup = TaskGroup.newBuilder().setTaskCount(1).setTaskSpec(task).build();

            // Policies are used to define on what kind of virtual machines the tasks will run on.
            InstancePolicy instancePolicy =
                    InstancePolicy.newBuilder().setMachineType("n2-highcpu-32").build();

            AllocationPolicy allocationPolicy =
                    AllocationPolicy.newBuilder()
                            .setServiceAccount(ServiceAccount.newBuilder().setEmail("tag-dispatcher-gcs@bqsc-host-v1.iam.gserviceaccount.com").build())
                            .addInstances(InstancePolicyOrTemplate.newBuilder().setPolicy(instancePolicy).build())
                            .build();

            Job job =
                    Job.newBuilder()
                            .addTaskGroups(taskGroup)
                            .setAllocationPolicy(allocationPolicy)
                            .putLabels("env", "testing")
                            .putLabels("type", "container")
                            // We use Cloud Logging as it's an out of the box available option.
                            .setLogsPolicy(
                                    LogsPolicy.newBuilder().setDestination(Destination.CLOUD_LOGGING).build())
                            .build();

            CreateJobRequest createJobRequest =
                    CreateJobRequest.newBuilder()
                            // The job's parent is the region in which the job will run.
                            .setParent(String.format("projects/%s/locations/%s", projectId, region))
                            .setJob(job)
                            .setJobId(jobName)
                            .build();

            Job result =
                    batchServiceClient
                            .createJobCallable()
                            .futureCall(createJobRequest)
                            .get(5, TimeUnit.MINUTES);

            System.out.printf("Successfully created the job: %s", result.getName());
        }
    }
}