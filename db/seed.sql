INSERT INTO site_settings (key, value) VALUES
  ('name', 'Amirhossein Akhlaghpour'),
  ('subtitle', 'Senior Systems & Backend Developer'),
  ('availability_text', 'Based in UK (UTC+0)'),
  ('github_url', 'https://github.com/mehrbod2002'),
  ('linkedin_url', 'https://www.linkedin.com/in/amirhossein-akhlaghpour-84676392/'),
  ('email', 'm9.akhlaghpoor@gmail.com'),
  ('phone', '+44 7367 046857'),
  ('footer_meta', 'Built with HTML, CSS, Mermaid.js. Lighthouse Score: 100/100.');

INSERT INTO about_paragraphs (content, position) VALUES
  ('Senior systems and backend engineer with 6+ years building Go/Rust platforms for fintech and blockchain products, from high-throughput APIs to low-latency streaming services.', 1),
  ('I have led microservice re-architecture, event-driven data pipelines, and Kubernetes/AWS deployments, improving reliability, scalability, and delivery speed while keeping costs predictable.', 2),
  ('Known for clean system design, secure middleware, and pragmatic execution—turning complex requirements into production-ready systems that teams can operate and evolve.', 3);

INSERT INTO showcase_items (title, meta, body, why, diagram_mermaid, position) VALUES
  ('High-Performance Fintech Systems — InfoStride', 'Situation → Action → Result', 'Re-architected Go/Rust microservices with deterministic concurrency, AWS Lambda/SQS orchestration, and optimized DynamoDB data paths to unlock 30% throughput gains and 50% faster deployments.', 'Why: I kept SQS in the critical path to preserve backpressure and isolate burst load from DynamoDB hot partitions.', 'flowchart LR\n  A[Go/Rust Services] --> B[AWS SQS]\n  B --> C[DynamoDB]\n  A --> D[API Gateway]', 1),
  ('Scalable Blockchain Infrastructure — Novatore Solutions', 'Situation → Action → Result', 'Integrated <a href=\"#ethereum\">Ethereum</a>, <a href=\"#kafka\">Kafka</a>, and <a href=\"#grpc\">gRPC</a> pipelines with hardened middleware security and structured telemetry, reducing errors by 40% while improving deterministic scalability.', 'Why: I chose Kafka to decouple ledger writes from API ingress, preserving throughput during network congestion.', NULL, 2),
  ('Low-Latency Video Delivery — Custom LMS', 'Situation → Action → Result', 'Built Rust-based streaming services using <a href=\"#grpc\">gRPC</a> and GStreamer RTMP pipelines to deliver stable, low-latency playback for interactive learning sessions.', 'Why: I chose Rust over Go for the streaming component to leverage zero-cost abstractions and fine-grained memory control over GStreamer buffers.', 'flowchart LR\n  A[Rust Stream Service] --> B[gRPC Control Plane]\n  A --> C[GStreamer RTMP]\n  C --> D[Edge CDN]', 3);

INSERT INTO skills_groups (title, content, anchor_id, position) VALUES
  ('Languages', 'Golang, Rust, TypeScript', NULL, 1),
  ('Infrastructure & DevOps', 'AWS (Lambda, DynamoDB, SQS), Kubernetes (CKA), Terraform', NULL, 2),
  ('Blockchain', 'Ethereum, Solidity, Smart Contracts, Chainlink', 'ethereum', 3),
  ('Backend Ecosystem', 'gRPC, <span id=\"kafka\">Kafka</span>, Redis, Prometheus/Grafana', 'grpc', 4);

INSERT INTO trust_badges (image, alt, position) VALUES
  ('assets/aws_cert.png', 'AWS Certified Developer – Associate', 1),
  ('assets/kubernetes_cert.png', 'Certified Kubernetes Administrator (CKA)', 2),
  ('assets/terraform_cert.png', 'Terraform Associate', 3);

INSERT INTO blog_posts (title, published_label, summary, position) VALUES
  ('High-throughput backends without latency spikes', 'Dec 2024', 'A practical look at deterministic concurrency patterns in Go/Rust services and how they tame tail latency under real-world traffic.', 1),
  ('Scaling blockchain middleware with Kafka and gRPC', 'Aug 2024', 'Lessons learned while hardening Ethereum pipelines, improving observability, and cutting error rates by 40%.', 2),
  ('Low-latency streaming pipelines in Rust', 'May 2024', 'Building RTMP video delivery with GStreamer, backpressure-aware queues, and performance-first profiling.', 3);

INSERT INTO research_items (title, slug, meta, summary, position) VALUES
  ('Comparing Concurrency Models: Go Channels vs. Rust Arc/Mutex in High-Throughput Fintech', 'comparing-concurrency', 'Deep dive', 'A systems-level comparison of contention patterns, memory ownership, and deterministic scalability when modeling transactional pipelines with Go channels versus Rust Arc/Mutex.', 1),
  ('Secure blockchain middleware', 'blockchain-middleware', 'Web3 infrastructure', 'Patterns for resilient Ethereum transaction routing, audit-grade observability, and error reduction at scale.', 2),
  ('Streaming systems for real-time learning', 'streaming-systems', 'Low-latency delivery', 'Exploring backpressure-aware pipelines, gRPC control planes, and RTMP delivery with GStreamer in Rust.', 3);

INSERT INTO research_pages (slug, title, meta, description, content_html) VALUES
  ('comparing-concurrency', 'Comparing Concurrency Models: Go Channels vs. Rust Arc/Mutex in High-Throughput Fintech', 'Deep dive', 'Comparing Go channels vs Rust Arc/Mutex for deterministic scalability in high-throughput fintech systems.', $$
          <h3>Overview</h3>
          <p>
            In high-throughput financial systems, the choice of concurrency primitives directly
            impacts tail latency and system reliability. While Golang’s CSP-based model focuses on
            simplicity and "sharing memory by communicating," Rust’s memory-safety guarantees allow
            for high-performance shared-state concurrency using atomics and smart pointers. This
            article explores the trade-offs encountered while building transactional pipelines at
            scale.
          </p>

          <h3>1. The Go Approach: CSP and Channel Orchestration</h3>
          <p>
            Go’s primary strength in fintech services is its lightweight scheduler and
            <code>channels</code>. In my experience building microservices at InfoStride, we used
            channels to decouple transaction ingestion from persistent storage.
          </p>
          <p>
            <strong>Pros:</strong> Minimal boilerplate for worker pools and excellent handling of
            asynchronous I/O.
          </p>
          <p>
            <strong>The Challenge:</strong> In extreme high-load scenarios, channel contention can
            introduce unpredictable latency spikes. Under heavy backpressure, the overhead of the Go
            runtime scheduler (G-M-P model) becomes visible when managing tens of thousands of
            concurrent goroutines.
          </p>
          <pre class="code-block"><code>// Go: incrementing a counter with a channel
package main

import "fmt"

func main() {
  ch := make(chan int)
  go func() {
    count := 0
    for v := range ch {
      count += v
      fmt.Println(count)
    }
  }()
  ch <- 1
  close(ch)
}</code></pre>

          <h3>2. The Rust Approach: Ownership and Fearless Concurrency</h3>
          <p>
            When sub-millisecond latency is non-negotiable—such as in order-matching engines or
            blockchain middleware—Rust’s <code>Arc&lt;Mutex&lt;T&gt;&gt;</code> or
            <code>RwLock&lt;T&gt;</code> often outperform CSP.
          </p>
          <p>
            <strong>Memory Safety:</strong> Rust’s borrow checker ensures that data races are caught
            at compile time, a critical feature when handling sensitive financial state.
          </p>
          <p>
            <strong>Performance:</strong> Unlike Go, Rust does not have a garbage collector (GC),
            meaning there are no "Stop-the-World" pauses during high-frequency trading or streaming.
          </p>
          <p>
            <strong>The Trade-off:</strong> Implementing shared state in Rust requires a deeper
            understanding of memory ownership and lock granularity to avoid deadlocks.
          </p>
          <pre class="code-block"><code>// Rust: incrementing a counter with Arc<Mutex<i32>>
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
  let counter = Arc::new(Mutex::new(0));
  let counter_clone = Arc::clone(&counter);
  let handle = thread::spawn(move || {
    let mut num = counter_clone.lock().unwrap();
    *num += 1;
    println!("{}", *num);
  });
  handle.join().unwrap();
}</code></pre>

          <h3>3. Real-world Comparison: A Transaction Pipeline Case Study</h3>
          <table>
            <thead>
              <tr>
                <th>Feature</th>
                <th>Golang (Channels)</th>
                <th>Rust (Arc/Mutex)</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Development Speed</td>
                <td>High (Rapid Iteration)</td>
                <td>Moderate (Strict Type System)</td>
              </tr>
              <tr>
                <td>Latency Consistency</td>
                <td>Occasional GC/Scheduler Spikes</td>
                <td>Deterministic</td>
              </tr>
              <tr>
                <td>Resource Efficiency</td>
                <td>Low Memory Footprint</td>
                <td>Minimal (Near C++)</td>
              </tr>
              <tr>
                <td>Complexity</td>
                <td>Simple Composition</td>
                <td>High (Lifetime Management)</td>
              </tr>
            </tbody>
          </table>

          <h3>4. Conclusion: Which one to choose?</h3>
          <p>
            For most microservices where developer velocity and "good enough" performance are key,
            <strong>Go</strong> remains the industry standard. However, for systems requiring
            deterministic scalability and zero-overhead concurrency—like the RTMP streaming services
            in our LMS project—<strong>Rust</strong> is the superior choice.
          </p>
          <p>
            In my current workflow, I bridge these two worlds: using Go for robust API orchestration
            and Rust for the high-performance core logic where every microsecond counts.
          </p>
          <p>Related work: <a href="index.html#showcase">InfoStride and LMS case studies</a>.</p>
          <p><a href="research.html">Back to Research</a></p>
  $$),
  ('blockchain-middleware', 'Secure blockchain middleware', 'Web3 infrastructure', 'Research notes on secure blockchain middleware, Ethereum routing, and observability.', $$
          <p>
            This research note focuses on resilient Ethereum transaction routing, audit-grade
            observability, and error reduction at scale. It connects the middleware patterns used in
            fintech backends with the security guarantees required for blockchain settlement.
          </p>
          <p>Related work: <a href="index.html#showcase">Novatore Solutions case study</a>.</p>
          <p><a href="research.html">Back to Research</a></p>
  $$),
  ('streaming-systems', 'Streaming systems for real-time learning', 'Low-latency delivery', 'Research notes on low-latency streaming systems using Rust, gRPC, and GStreamer.', $$
          <p>
            This research note covers backpressure-aware pipelines, gRPC control planes, and RTMP
            delivery with GStreamer in Rust, with a focus on deterministic latency during peak load.
          </p>
          <p>Related work: <a href="index.html#showcase">Custom LMS case study</a>.</p>
          <p><a href="research.html">Back to Research</a></p>
  $$);

INSERT INTO experiences (company, role, description, years, position) VALUES
  ('InfoStride', 'Senior Systems & Backend Developer', 'Go/Rust microservices, AWS Lambda/SQS, Terraform automation.', '2024–2025', 1),
  ('Novatore Solutions', 'Backend Developer', 'Ethereum middleware, Kafka/gRPC pipelines, CI/CD automation.', '2022–2024', 2),
  ('Livemindz', 'Backend Developer', 'Go/Rust microservices, JWT gateways, Redis queues.', '2019–2022', 3);
