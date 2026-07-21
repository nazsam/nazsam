# Securing RAG Pipelines: Data Leakage Risks in Retrieval-Augmented Generation

*By S. Naz · Cybersecurity, Cloud & AI Security Leader*

Retrieval-Augmented Generation lets an LLM answer questions using your organization's own documents instead of relying purely on training data — and it's become the default architecture for internal AI assistants. It also quietly reintroduces every access-control problem your document stores already had, plus a few new ones specific to how retrieval works.

## The Core Problem: Retrieval Doesn't Know About Permissions

A RAG pipeline typically indexes documents into a vector database and retrieves the most relevant chunks for a given query, feeding them to the model as context. If that indexing process doesn't preserve the original document's access controls, you've built a system where anyone who can query the assistant can effectively read anything that was indexed — regardless of whether they had permission to read the source document.

## Where Leakage Actually Happens

Three failure points show up repeatedly: indexing pipelines that flatten permission metadata during ingestion, chat interfaces that don't filter retrieved chunks by the querying user's actual access rights, and prompt injection embedded in indexed documents that manipulates the model into surfacing content it should have withheld. Each needs a distinct control, not a single fix.

## Building It Securely From the Start

Preserve source-document ACLs through the entire pipeline and enforce them at query time, not just at ingestion — a document's permissions can change after it's indexed, and stale permissions in your vector store are a real risk. Apply row-level or document-level filtering in the retrieval step based on the requesting user's identity. And treat retrieved content the same way you'd treat any other untrusted input reaching the model — sanitize for injection patterns before it becomes part of the prompt.

## Key Takeaways

- RAG systems inherit the access-control requirements of every document they index — this doesn't happen automatically.
- Enforce permissions at query time, not just at ingestion time.
- Retrieved content is untrusted input and needs the same injection defenses as any external data source.

---
*Part of the [devsecforge](https://github.com/devsecforge/devsecforge) writing series — also cross-posted on [LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
