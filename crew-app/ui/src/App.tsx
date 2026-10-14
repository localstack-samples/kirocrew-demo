import { useAppApi } from '@kirocrew/app-sdk'
import { Badge, Card, CardTitle, EmptyState, PageHeader, StatCard } from '@kirocrew/app-sdk/ui'
import { useEffect, useState } from 'react'

type Run = { status: 'passed' | 'failed'; summary: string; diagnostic: string; recorded_at: string }

export default function LocalStackOpsDashboard() {
  const api = useAppApi()
  const [runs, setRuns] = useState<Run[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    // KiroCrew proxies /apps/<app>/api/* to this app's backend as /api/*.
    const load = () => api.get('/apps/localstack-ops/api/history')
      .then((data: { runs?: Run[] }) => { setRuns(data.runs ?? []); setError('') })
      .catch((err: unknown) => setError(err instanceof Error ? err.message : String(err)))
      .finally(() => setLoading(false))
    // Scheduled runs finish while the page is open, so keep the history current.
    load()
    const timer = window.setInterval(load, 15000)
    window.addEventListener('focus', load)
    return () => {
      window.clearInterval(timer)
      window.removeEventListener('focus', load)
    }
  }, [])

  const latest = runs[0]
  const failures = runs.filter((run) => run.status === 'failed').length
  return <>
    <PageHeader title="LocalStack Ops" subtitle="Scheduled S3 → Lambda → DynamoDB verification" />
    <div className="px-6 pb-8 overflow-y-auto flex-1 min-h-0">
      <div className="grid gap-3.5 grid-cols-[repeat(auto-fit,minmax(150px,1fr))] mb-6">
        <StatCard label="Last run" value={latest?.status === 'passed' ? 'Passed' : latest ? 'Failed' : 'Pending'} accent={latest?.status === 'passed'} />
        <StatCard label="Recorded runs" value={runs.length} />
        <StatCard label="Failures" value={failures} />
      </div>
      {loading ? <Card><CardTitle>Loading run history…</CardTitle></Card> : error ?
        <EmptyState title="Could not load run history" description={error} /> : runs.length === 0 ?
        <EmptyState title="No runs recorded" description="Trigger the LocalStack Ops schedule or ask its agent to run the deploy-and-smoke workflow." /> :
        runs.map((run, index) => <Card key={`${run.recorded_at}-${index}`} className="mb-4">
          <CardTitle>{new Date(run.recorded_at).toLocaleString()} <Badge>{run.status}</Badge></CardTitle>
          <p className="text-sm mt-2">{run.summary}</p>
          {run.diagnostic && <p className="text-sm text-muted mt-2 whitespace-pre-wrap">{run.diagnostic}</p>}
        </Card>)}
    </div>
  </>
}
