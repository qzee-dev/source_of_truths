flowchart TB
    %% Top-level org and governance
    subgraph A["Generated starter: AWS Organizations + account model"]
        Org["AWS Organizations\nRoot + SCPs + Tag Policies"]
        subgraph OUs["Organizational Units"]
            SecurityOU["Security-OU"]
            InfraOU["Infrastructure-OU"]
            ProdOU["Workloads-Prod-OU"]
            NonProdOU["Workloads-NonProd-OU"]
            SandboxOU["Sandbox-OU"]
        end

        Management["Management Account"]
        LogArchive["Log Archive Account"]
        SecTooling["Security Tooling Account"]
        NetworkAcct["Network Account"]
        SharedSys["Shared-System Account"]
        ProdAcct["Production Account"]
        StageAcct["Staging Account"]
        DevAcct["Development Account"]
        SandboxAcct["Sandbox Account"]

        Org --> SecurityOU
        Org --> InfraOU
        Org --> ProdOU
        Org --> NonProdOU
        Org --> SandboxOU

        SecurityOU --> LogArchive
        SecurityOU --> SecTooling

        InfraOU --> NetworkAcct
        InfraOU --> SharedSys

        ProdOU --> ProdAcct
        NonProdOU --> StageAcct
        NonProdOU --> DevAcct
        SandboxOU --> SandboxAcct
    end

    %% Core security and control plane
    subgraph B["Generated starter: foundational controls"]
        SCP["Baseline SCP\nProd SCP\nNonProd SCP\nSandbox SCP"]
        State["Terraform Remote State\nS3 bucket + DynamoDB lock"]
        KMS["KMS Keys\nState / Config / Security"]
        SecurityStack["Security Stack\nSecurity Hub\nGuardDuty\nAWS Config\nCloudTrail"]
        TagPolicy["Tag Policy\nEnvironment, ProjectID, Owner,\nCostCenter, Compliance, Automation"]
    end

    Org --> SCP
    Org --> TagPolicy
    State --> KMS
    SecurityStack --> KMS

    %% Network core
    subgraph C["Generated starter: network foundation"]
        InspectionVPC["Inspection VPC\n10.30.0.0/16"]
        SharedVPC["Shared Services VPC\n10.40.0.0/16"]
        ProdVPC["Production VPC\n10.50.0.0/16"]
        StageVPC["Staging VPC\n10.60.0.0/16"]
        DevVPC["Development VPC\n10.70.0.0/16"]
        TGW["Transit Gateway\nHub-and-Spoke"]
    end

    NetworkAcct --> InspectionVPC
    SharedSys --> SharedVPC
    ProdAcct --> ProdVPC
    StageAcct --> StageVPC
    DevAcct --> DevVPC

    InspectionVPC --> TGW
    SharedVPC --> TGW
    ProdVPC --> TGW
    StageVPC --> TGW
    DevVPC --> TGW

    %% Shared services and workload layering
    subgraph D["Generated starter: shared services + workloads"]
        DNS["Route53 Private Zone\nResolver"]
        AD["Microsoft AD\ncorp.example.internal"]
        AppProd["Workload Prod\nRDS / app resources"]
        AppStage["Workload Stage"]
        AppDev["Workload Dev"]
        SandboxWork["Sandbox workload"]
    end

    SharedVPC --> DNS
    SharedVPC --> AD
    ProdVPC --> AppProd
    StageVPC --> AppStage
    DevVPC --> AppDev
    SandboxAcct --> SandboxWork

    %% Future missing components
    subgraph E["Future required layers (not yet generated)"]
        IAMIC["IAM Identity Center\nPermission Sets + SSO"]
        CrossRole["Cross-account IAM roles\nTrust relationships"]
        TGWRoutes["TGW route tables\nroute propagation\nstatic routes"]
        NACL["Network ACLs + Security Groups\nleast privilege hardening"]
        OnPrem["On-prem DC / Branch\nDirect Connect + VPN"]
        Secrets["Secrets Manager / SSM\nAD password + DB password + keys"]
        CI["CI/CD + policy validation\nterraform plan/apply automation"]
        Audit["Operational controls\nremediation + drift detection + compliance workflows"]
    end

    Org --> IAMIC
    IAMIC --> CrossRole
    TGW --> TGWRoutes
    TGW --> OnPrem
    TGWRoutes --> NACL
    AppProd --> Secrets
    State --> CI
    SecurityStack --> Audit

    %% Cross-links between current and future
    DNS --> OnPrem
    AD --> CrossRole
    TGW --> IAMIC
