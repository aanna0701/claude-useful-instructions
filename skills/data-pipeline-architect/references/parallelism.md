# Parallelism & Multiprocessing Principle

This document defines when and how to apply multiprocessing in data pipeline stages.
Referenced in Phase 2 (stage identification) and Phase 4 (instruction generation).

---

## Three Levels of Parallelism

### Level 1: Intra-Stage Parallelism (Within a Single Stage)

A single stage processes multiple data items concurrently.
This is the most common and safest form of parallelism.

**When to apply:**
- Each item can be processed independently (no shared mutable state)
- Processing is CPU-bound or I/O-bound with high latency
- Item count is large enough to justify process/thread overhead

**Implementation patterns:**
- `multiprocessing.Pool.map()` for CPU-bound work (image processing, checksum, parsing)
- `concurrent.futures.ProcessPoolExecutor` for CPU-bound with better error handling
- `concurrent.futures.ThreadPoolExecutor` for I/O-bound work (API calls, file reads)
- `asyncio.gather()` for async I/O-bound work

**Example:**
```python
from concurrent.futures import ProcessPoolExecutor
from functools import partial

def process_single_item(item: RawRecord, config: Config) -> ProcessedRecord:
    """Pure function - no side effects, no shared state."""
    ...

def run_stage(items: list[RawRecord], config: Config) -> list[ProcessedRecord]:
    process_fn = partial(process_single_item, config=config)
    with ProcessPoolExecutor(max_workers=config.num_workers) as pool:
        results = list(pool.map(process_fn, items, chunksize=config.chunk_size))
    return results
```

### Level 2: Inter-Stage Parallelism (Between Stages)

Independent stages run concurrently when there are no data dependencies.

**When to apply:**
- Two or more stages have no input/output dependency
- Stages read from different sources or write to different targets
- The pipeline DAG has parallel branches

**Implementation patterns:**
- Orchestrator analyzes dependency graph and launches independent stages concurrently
- Use `concurrent.futures.ProcessPoolExecutor` or `asyncio.gather()` at orchestrator level
- Each stage still runs in its own process for fault isolation

**Example:**
```python
# Stages 2, 3, 4 are independent (all depend only on Stage 1)
async def run_parallel_stages(stage1_output):
    results = await asyncio.gather(
        run_stage_2(stage1_output),
        run_stage_3(stage1_output),
        run_stage_4(stage1_output),
    )
    return results
```

### Level 3: Data Parallelism (Partition-Based)

A single stage's input is partitioned, and each partition is processed independently.

**When to apply:**
- Data is naturally partitionable (by date, by source, by ID range)
- Each partition can be processed without knowledge of other partitions
- Data volume is large enough to benefit from partitioning

**Implementation patterns:**
- Partition by natural key (date, source_id, region)
- Each partition processed by a separate worker
- Results merged after all partitions complete
- Checkpoint per partition for granular failure recovery

---

## Parallelism Analysis Checklist (Per Stage)

For each stage identified in Phase 2, evaluate:

```yaml
stage: "Stage N: [name]"
parallelism:
  intra_stage:
    applicable: true/false
    type: "cpu_bound" | "io_bound" | "mixed"
    unit: "per_file" | "per_record" | "per_batch" | "per_partition"
    shared_state: true/false  # false = safe to parallelize
    estimated_speedup: "Nx"   # rough estimate
    pattern: "ProcessPoolExecutor" | "ThreadPoolExecutor" | "asyncio"
  inter_stage:
    independent_of: ["Stage X", "Stage Y"]  # stages that can run in parallel
    depends_on: ["Stage Z"]
  data_parallelism:
    applicable: true/false
    partition_key: "date" | "source_id" | "id_range" | null
    merge_strategy: "concat" | "reduce" | null
```

---

## Safety Rules

### Rule 1: Pure Functions First
Parallelized work units MUST be pure functions (no side effects, no shared mutable state).
If a function writes to a shared resource (DB, file), synchronize access or batch writes after parallel processing.

### Rule 2: Chunk Size Tuning
- Too small: overhead dominates (IPC cost per item)
- Too large: memory pressure, uneven load distribution
- Default: `max(1, len(items) // (num_workers * 4))`
- Always make chunk_size configurable

### Rule 3: Error Handling in Parallel Context
- One worker failure must not crash the entire stage
- Capture per-item errors and route to DLQ
- Use `concurrent.futures` which propagates exceptions cleanly

```python
from concurrent.futures import ProcessPoolExecutor, as_completed

results = []
errors = []
with ProcessPoolExecutor(max_workers=num_workers) as pool:
    futures = {pool.submit(process_item, item): item for item in items}
    for future in as_completed(futures):
        item = futures[future]
        try:
            results.append(future.result())
        except Exception as e:
            errors.append(DeadLetter(record=item, error=str(e), ...))
```

### Rule 4: Resource Limits
- `num_workers` defaults to `min(cpu_count(), 8)` — never unbounded
- Memory per worker must be estimated and total must fit in available RAM
- File descriptor limits: each worker may open files, check `ulimit -n`

### Rule 5: Idempotency Preserved
Parallelism must not break idempotency (R1).
- Each worker writes to its own partition/temp file
- Final merge is atomic (staging area + rename)
- Progress tracker must be per-item or per-partition, not global

### Rule 6: Observability in Parallel Context
- Each worker logs to a shared structured log (thread-safe)
- Audit counts must be aggregated across workers: `sum(worker_counts)`
- Progress reporting: use `tqdm` with multiprocessing support or periodic aggregation

---

## Anti-Patterns

| Anti-Pattern | Why It Fails | Correct Approach |
|---|---|---|
| Shared mutable dict/list across processes | Race conditions, corruption | Each worker returns results, aggregate after |
| Global DB connection in multiprocessing | Connection not fork-safe | Create connection per worker |
| `multiprocessing` for I/O-bound work | GIL not the bottleneck, process overhead wasted | Use `ThreadPoolExecutor` or `asyncio` |
| `threading` for CPU-bound work | GIL prevents true parallelism | Use `ProcessPoolExecutor` |
| Unbounded worker count | OOM, context switch overhead | Cap at `min(cpu_count(), 8)` |
| Parallelizing tiny workloads (<100 items) | Overhead > benefit | Sequential is faster |

---

## When NOT to Parallelize

- Data volume is small (< 100 items or < 1 second sequential)
- Items have sequential dependencies (item N depends on item N-1)
- Stage is already I/O-bound on a single resource (single DB, single API with rate limit)
- Debugging/development phase (parallel errors are harder to trace)
- The stage modifies shared state that cannot be partitioned
