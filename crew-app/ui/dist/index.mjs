import { jsxs as o, Fragment as x, jsx as t } from "react/jsx-runtime";
import { useAppApi as L } from "@kirocrew/app-sdk";
import { PageHeader as S, StatCard as n, Card as m, CardTitle as p, EmptyState as u, Badge as b } from "@kirocrew/app-sdk/ui";
import { useState as d, useEffect as y } from "react";
function D() {
  const h = L(), [s, f] = d([]), [g, w] = d(!0), [l, c] = d("");
  y(() => {
    const e = () => h.get("/apps/localstack-ops/api/history").then((r) => {
      f(r.runs ?? []), c("");
    }).catch((r) => c(r instanceof Error ? r.message : String(r))).finally(() => w(!1));
    e();
    const i = window.setInterval(e, 15e3);
    return window.addEventListener("focus", e), () => {
      window.clearInterval(i), window.removeEventListener("focus", e);
    };
  }, []);
  const a = s[0], v = s.filter((e) => e.status === "failed").length;
  return /* @__PURE__ */ o(x, { children: [
    /* @__PURE__ */ t(S, { title: "LocalStack Ops", subtitle: "Scheduled S3 → Lambda → DynamoDB verification" }),
    /* @__PURE__ */ o("div", { className: "px-6 pb-8 overflow-y-auto flex-1 min-h-0", children: [
      /* @__PURE__ */ o("div", { className: "grid gap-3.5 grid-cols-[repeat(auto-fit,minmax(150px,1fr))] mb-6", children: [
        /* @__PURE__ */ t(n, { label: "Last run", value: (a == null ? void 0 : a.status) === "passed" ? "Passed" : a ? "Failed" : "Pending", accent: (a == null ? void 0 : a.status) === "passed" }),
        /* @__PURE__ */ t(n, { label: "Recorded runs", value: s.length }),
        /* @__PURE__ */ t(n, { label: "Failures", value: v })
      ] }),
      g ? /* @__PURE__ */ t(m, { children: /* @__PURE__ */ t(p, { children: "Loading run history…" }) }) : l ? /* @__PURE__ */ t(u, { title: "Could not load run history", description: l }) : s.length === 0 ? /* @__PURE__ */ t(u, { title: "No runs recorded", description: "Trigger the LocalStack Ops schedule or ask its agent to run the deploy-and-smoke workflow." }) : s.map((e, i) => /* @__PURE__ */ o(m, { className: "mb-4", children: [
        /* @__PURE__ */ o(p, { children: [
          new Date(e.recorded_at).toLocaleString(),
          " ",
          /* @__PURE__ */ t(b, { children: e.status })
        ] }),
        /* @__PURE__ */ t("p", { className: "text-sm mt-2", children: e.summary }),
        e.diagnostic && /* @__PURE__ */ t("p", { className: "text-sm text-muted mt-2 whitespace-pre-wrap", children: e.diagnostic })
      ] }, `${e.recorded_at}-${i}`))
    ] })
  ] });
}
export {
  D as default
};
