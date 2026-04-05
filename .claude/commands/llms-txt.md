---
name: llms-txt
description: Fetch raw llms.txt documentation for a library or direct URL. Use when you explicitly want raw /llms.txt content or when official Context7 is unavailable.
argument-hint: nextjs | prisma | supabase | [custom-url]
allowed-tools: Bash(curl:*)
---

# /llms-txt Command

Fetch LLM-optimized documentation for libraries.

## Library
$ARGUMENTS

## Common URLs
| Library | URL |
|---------|-----|
| Next.js | https://nextjs.org/llms.txt |
| Prisma | https://prisma.io/llms.txt |
| Supabase | https://supabase.com/llms.txt |
| Vercel | https://vercel.com/llms.txt |
| Helius | https://www.helius.dev/docs/llms.txt |
| Tailwind | https://tailwindcss.com/llms.txt |

## Execution

Based on the library name:
1. Try `https://[library].org/llms.txt`
2. Try `https://[library].io/llms.txt`
3. Try `https://[library].com/llms.txt`
4. Try `https://docs.[library].io/llms.txt`

For custom URLs, fetch directly.

```bash
# Example
curl -s https://nextjs.org/llms.txt | head -200
```

## When to Use
- You explicitly want the raw `/llms.txt` file
- You want a direct URL-based docs fetch
- You need a quick one-shot raw-doc pull instead of official Context7

## Examples
```
/llms-txt nextjs          # Next.js 문서
/llms-txt prisma          # Prisma 문서
/llms-txt https://custom.dev/llms.txt  # Custom URL
```
