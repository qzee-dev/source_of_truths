flowchart LR
    subgraph Org["AWS Organizations"]
        Root["Root"]
        SecurityOU["Security-OU"]
        InfraOU["Infrastructure-OU"]
        ProdOU["Workloads-Prod-OU"]
        NonProdOU["Workloads-NonProd-OU"]
        SandboxOU["Sandbox-OU"]
    end

    Root --> SecurityOU
    Root --> InfraOU
    Root --> ProdOU
    Root --> NonProdOU
    Root --> SandboxOU

    SecurityOU --> LogArchive["Log Archive Account"]
    SecurityOU --> SecTooling["Security Tooling Account"]

    InfraOU --> NetworkAcct["Network Account"]
    InfraOU --> SharedSys["Shared-System Account"]

    ProdOU --> ProdAcct["Production Account"]
    NonProdOU --> StageAcct["Staging Account"]
    NonProdOU --> DevAcct["Development Account"]
    SandboxOU --> SandboxAcct["Sandbox Account"]

    NetworkAcct --> InspectionVPC["Inspection VPC\n10.30.0.0/16"]
    SharedSys --> SharedVPC["Shared-Services VPC\n10.40.0.0/16"]
    ProdAcct --> ProdVPC["Prod VPC\n10.50.0.0/16"]
    StageAcct --> StageVPC["Stage VPC\n10.60.0.0/16"]
    DevAcct --> DevVPC["Dev VPC\n10.70.0.0/16"]

    SharedVPC --> AD["AD / DNS"]
    ProdVPC --> ProdApp["Prod workload"]
    StageVPC --> StageApp["Stage workload"]
    DevVPC --> DevApp["Dev workload"]
    SandboxAcct --> SandboxApp["Sandbox workload"]

    TGW["Transit Gateway\nHub + Spoke"] 
    InspectionVPC --> TGW
    SharedVPC --> TGW
    ProdVPC --> TGW
    StageVPC --> TGW
    DevVPC --> TGW

    SCP["SCPs\nBaseline / Prod / NonProd / Sandbox"]
    SecurityStack["Security Hub\nGuardDuty\nConfig\nCloudTrail"]
    KMS["KMS"]
    State["S3 State\nDynamoDB Locks"]

    Root --> SCP
    SecurityOU --> SecurityStack
    SecurityStack --> KMS
    State --> KMS
