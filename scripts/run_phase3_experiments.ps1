param(
    [string]$Tla2ToolsJar,
    [string]$OutputDirectory = "evaluation",
    [string]$MetaRoot,
    [int]$Workers = 1,
    [int]$HeapGB = 4,
    [string[]]$Only = @()
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repoRoot

if (-not $Tla2ToolsJar) {
    $candidate = Get-ChildItem `
        "$env:USERPROFILE\.vscode\extensions\tlaplus.vscode-ide-*\tools\tla2tools.jar" `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $candidate) {
        throw "Pass -Tla2ToolsJar or install the VS Code TLA+ extension."
    }
    $Tla2ToolsJar = $candidate.FullName
}
$Tla2ToolsJar = (Resolve-Path $Tla2ToolsJar).Path

if (-not $MetaRoot) {
    $drive = Get-PSDrive D -ErrorAction SilentlyContinue
    if ($drive -and $drive.Free -gt 10GB) {
        $MetaRoot = "D:\tlc-chord-phase3"
    } else {
        $MetaRoot = Join-Path $env:TEMP "tlc-chord-phase3"
    }
}

$outputPath = Join-Path $repoRoot $OutputDirectory
$logPath = Join-Path $outputPath "logs"
New-Item -ItemType Directory -Force -Path $outputPath, $logPath, $MetaRoot | Out-Null
$resolvedMetaRoot = (Resolve-Path $MetaRoot).Path

$experiments = @(
    [pscustomobject]@{ id="dynamic-m2-n3-one-join-invariant"; category="dynamic_matrix"; scenario="M2-N3-J1"; m=2; initial_nodes=2; joins=1; final_nodes=3; verification="invariant"; routing="n/a"; constrained="n/a"; model="ChordDynamic.tla"; config="configs/evaluation/dynamic/m2-n3-j1-invariant.cfg"; properties="TypeOK; SuccessorCoreReachable; deadlock" },
    [pscustomobject]@{ id="dynamic-m2-n3-one-join-temporal"; category="dynamic_matrix"; scenario="M2-N3-J1"; m=2; initial_nodes=2; joins=1; final_nodes=3; verification="temporal"; routing="n/a"; constrained="n/a"; model="ChordDynamic.tla"; config="configs/evaluation/dynamic/m2-n3-j1-temporal.cfg"; properties="TypeOK; SuccessorCoreReachable; deadlock; EventuallyStableAfterJoins" },
    [pscustomobject]@{ id="dynamic-m3-n3-one-join-invariant"; category="dynamic_matrix"; scenario="M3-N3-J1"; m=3; initial_nodes=2; joins=1; final_nodes=3; verification="invariant"; routing="n/a"; constrained="n/a"; model="ChordDynamic.tla"; config="configs/evaluation/dynamic/m3-n3-j1-invariant.cfg"; properties="TypeOK; SuccessorCoreReachable; deadlock" },
    [pscustomobject]@{ id="dynamic-m3-n3-one-join-temporal"; category="dynamic_matrix"; scenario="M3-N3-J1"; m=3; initial_nodes=2; joins=1; final_nodes=3; verification="temporal"; routing="n/a"; constrained="n/a"; model="ChordDynamic.tla"; config="ChordDynamic.cfg"; properties="TypeOK; SuccessorCoreReachable; deadlock; EventuallyStableAfterJoins" },
    [pscustomobject]@{ id="dynamic-m3-n4-one-join-invariant"; category="dynamic_matrix"; scenario="M3-N4-J1"; m=3; initial_nodes=3; joins=1; final_nodes=4; verification="invariant"; routing="n/a"; constrained="n/a"; model="ChordDynamic.tla"; config="configs/evaluation/dynamic/m3-n4-j1-invariant.cfg"; properties="TypeOK; SuccessorCoreReachable; deadlock" },
    [pscustomobject]@{ id="dynamic-m3-n4-one-join-temporal"; category="dynamic_matrix"; scenario="M3-N4-J1"; m=3; initial_nodes=3; joins=1; final_nodes=4; verification="temporal"; routing="n/a"; constrained="n/a"; model="ChordDynamic.tla"; config="configs/evaluation/dynamic/m3-n4-j1-temporal.cfg"; properties="TypeOK; SuccessorCoreReachable; deadlock; EventuallyStableAfterJoins" },
    [pscustomobject]@{ id="dynamic-m3-n4-two-joins-invariant"; category="dynamic_matrix"; scenario="M3-N4-J2"; m=3; initial_nodes=2; joins=2; final_nodes=4; verification="invariant"; routing="n/a"; constrained="n/a"; model="ChordDynamic.tla"; config="configs/evaluation/dynamic/m3-n4-j2-invariant.cfg"; properties="TypeOK; SuccessorCoreReachable; deadlock" },
    [pscustomobject]@{ id="dynamic-m3-n4-two-joins-temporal"; category="dynamic_matrix"; scenario="M3-N4-J2"; m=3; initial_nodes=2; joins=2; final_nodes=4; verification="temporal"; routing="n/a"; constrained="n/a"; model="ChordDynamic.tla"; config="configs/evaluation/dynamic/m3-n4-j2-temporal.cfg"; properties="TypeOK; SuccessorCoreReachable; deadlock; EventuallyStableAfterJoins" },
    [pscustomobject]@{ id="static-m3-n4-finger"; category="lookup_baseline"; scenario="M3-N4"; m=3; initial_nodes=4; joins=0; final_nodes=4; verification="invariant"; routing="finger"; constrained="yes"; model="ChordStatic.tla"; config="configs/evaluation/lookup/m3-n4-finger.cfg"; properties="TypeOK; LookupCorrect" },
    [pscustomobject]@{ id="static-m3-n4-linear"; category="lookup_baseline"; scenario="M3-N4"; m=3; initial_nodes=4; joins=0; final_nodes=4; verification="invariant"; routing="successor-only"; constrained="yes"; model="ChordStatic.tla"; config="configs/evaluation/lookup/m3-n4-linear.cfg"; properties="TypeOK; LookupCorrect" },
    [pscustomobject]@{ id="static-m4-n8-finger"; category="lookup_baseline"; scenario="M4-N8"; m=4; initial_nodes=8; joins=0; final_nodes=8; verification="invariant"; routing="finger"; constrained="yes"; model="ChordStatic.tla"; config="configs/evaluation/lookup/m4-n8-finger.cfg"; properties="TypeOK; LookupCorrect" },
    [pscustomobject]@{ id="static-m4-n8-linear"; category="lookup_baseline"; scenario="M4-N8"; m=4; initial_nodes=8; joins=0; final_nodes=8; verification="invariant"; routing="successor-only"; constrained="yes"; model="ChordStatic.tla"; config="configs/evaluation/lookup/m4-n8-linear.cfg"; properties="TypeOK; LookupCorrect" },
    [pscustomobject]@{ id="static-m2-n2-unconstrained"; category="workload_baseline"; scenario="M2-N2"; m=2; initial_nodes=2; joins=0; final_nodes=2; verification="invariant"; routing="finger"; constrained="no"; model="ChordStatic.tla"; config="ChordStatic.cfg"; properties="TypeOK; LookupCorrect" },
    [pscustomobject]@{ id="static-m2-n2-one-query"; category="workload_baseline"; scenario="M2-N2"; m=2; initial_nodes=2; joins=0; final_nodes=2; verification="invariant"; routing="finger"; constrained="yes"; model="ChordStatic.tla"; config="configs/evaluation/workload/m2-n2-one-query.cfg"; properties="TypeOK; LookupCorrect" }
)

if ($Only.Count -gt 0) {
    $experiments = $experiments | Where-Object {
        $id = $_.id
        @($Only | Where-Object { $id -like $_ }).Count -gt 0
    }
}
if ($experiments.Count -eq 0) {
    throw "No experiments matched -Only."
}

$cpu = Get-CimInstance Win32_Processor
$computer = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$previousErrorPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$javaVersion = (& java -version 2>&1 | Select-Object -First 1).ToString()
$ErrorActionPreference = $previousErrorPreference

$environment = [pscustomobject]@{
    collected_at = (Get-Date).ToString("o")
    cpu = $cpu.Name.Trim()
    physical_cores = $cpu.NumberOfCores
    logical_processors = $cpu.NumberOfLogicalProcessors
    ram_gb = [string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:F1}", $computer.TotalPhysicalMemory / 1GB)
    os = $os.Caption
    os_version = $os.Version
    java = $javaVersion
    tla2tools_jar = $Tla2ToolsJar
    workers = $Workers
    heap_gb = $HeapGB
    garbage_collector = "ParallelGC"
    metadir_root = $resolvedMetaRoot
}
$environment | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $outputPath "environment.json")

$rows = [System.Collections.Generic.List[object]]::new()
foreach ($experiment in $experiments) {
    Write-Host "Running $($experiment.id)..."
    $runMeta = Join-Path $resolvedMetaRoot $experiment.id
    if (Test-Path $runMeta) {
        $resolvedRunMeta = (Resolve-Path $runMeta).Path
        if (-not $resolvedRunMeta.StartsWith($resolvedMetaRoot + [IO.Path]::DirectorySeparatorChar)) {
            throw "Refusing to remove metadir outside $resolvedMetaRoot"
        }
        Remove-Item -LiteralPath $resolvedRunMeta -Recurse -Force
    }

    $arguments = @(
        "-Xms${HeapGB}g",
        "-Xmx${HeapGB}g",
        "-XX:+UseParallelGC",
        "-cp", $Tla2ToolsJar,
        "tlc2.TLC",
        "-workers", $Workers,
        "-lncheck", "final",
        "-metadir", $runMeta,
        "-config", $experiment.config,
        $experiment.model
    )

    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $output = @(& java @arguments 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
    $stopwatch.Stop()

    $logFile = Join-Path $logPath "$($experiment.id).log"
    $output | Set-Content -Encoding utf8 $logFile
    $joined = $output -join "`n"

    $statesMatch = [regex]::Match($joined, "(\d+) states generated, (\d+) distinct states found")
    $depthMatch = [regex]::Match($joined, "depth of the complete state graph search is (\d+)")
    $tlcMatch = [regex]::Match($joined, "TLC2 Version ([^\r\n]+)")
    $passed = $exitCode -eq 0 -and $joined.Contains("Model checking completed. No error has been found.")
    if (-not $statesMatch.Success -or -not $depthMatch.Success) {
        throw "Could not parse TLC summary for $($experiment.id). See $logFile."
    }

    $generated = [long]$statesMatch.Groups[1].Value
    $distinct = [long]$statesMatch.Groups[2].Value
    $seconds = $stopwatch.Elapsed.TotalSeconds
    $rows.Add([pscustomobject]@{
        experiment_id = $experiment.id
        category = $experiment.category
        scenario = $experiment.scenario
        m = $experiment.m
        initial_nodes = $experiment.initial_nodes
        joins = $experiment.joins
        final_nodes = $experiment.final_nodes
        verification_mode = $experiment.verification
        routing_mode = $experiment.routing
        one_query_constraint = $experiment.constrained
        model = $experiment.model
        config = $experiment.config
        properties = $experiment.properties
        result = $(if ($passed) { "Passed" } else { "Failed" })
        states_generated = $generated
        distinct_states = $distinct
        depth = [int]$depthMatch.Groups[1].Value
        wall_seconds = [string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:F3}", $seconds)
        generated_states_per_second = [string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:F1}", $generated / $seconds)
        distinct_states_per_second = [string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:F1}", $distinct / $seconds)
        workers = $Workers
        heap_gb = $HeapGB
        tlc_version = $(if ($tlcMatch.Success) { $tlcMatch.Groups[1].Value.Trim() } else { "unknown" })
        run_at = (Get-Date).ToString("o")
    })

    if (-not $passed) {
        throw "TLC failed for $($experiment.id). See $logFile."
    }

    if (Test-Path $runMeta) {
        $resolvedRunMeta = (Resolve-Path $runMeta).Path
        if (-not $resolvedRunMeta.StartsWith($resolvedMetaRoot + [IO.Path]::DirectorySeparatorChar)) {
            throw "Refusing to remove metadir outside $resolvedMetaRoot"
        }
        Remove-Item -LiteralPath $resolvedRunMeta -Recurse -Force
    }
}

$csvPath = Join-Path $outputPath "phase3_results.csv"
$rows | Export-Csv -NoTypeInformation -Encoding utf8 $csvPath
Write-Host "Wrote $csvPath"
