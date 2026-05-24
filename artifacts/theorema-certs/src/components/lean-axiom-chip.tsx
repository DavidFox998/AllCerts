import { useGetLeanVerification } from "@workspace/api-client-react";
import { ShieldCheck, ShieldQuestion } from "lucide-react";

interface LeanAxiomChipProps {
  leanBinding: string;
  size?: "sm" | "md";
}

function bindingAppearsInAxiomLines(binding: string, lines: string[]): boolean {
  const last = binding.includes(".") ? binding.slice(binding.lastIndexOf(".") + 1) : binding;
  return lines.some((line) => line.includes(binding) || line.includes(last));
}

export function LeanAxiomChip({ leanBinding, size = "sm" }: LeanAxiomChipProps) {
  const { data } = useGetLeanVerification();

  const verified = !!data && bindingAppearsInAxiomLines(leanBinding, data.axiomLines);
  const padding = size === "sm" ? "px-2 py-0.5" : "px-3 py-1";
  const iconSize = size === "sm" ? "w-3 h-3" : "w-3.5 h-3.5";

  const title = verified
    ? `Lean: ${leanBinding} does not depend on any axioms`
    : data
      ? `Lean: ${leanBinding} not found in axiom verification lines`
      : `Lean verification log unavailable`;

  if (verified) {
    return (
      <span
        title={title}
        data-testid={`chip-lean-axiom-${leanBinding}`}
        className={`inline-flex items-center gap-1 ${padding} border border-green-500/50 bg-green-500/10 font-mono text-[10px] font-bold uppercase text-green-700 dark:text-green-400 whitespace-nowrap`}
      >
        <ShieldCheck className={iconSize} /> Lean: axiom debt = []
      </span>
    );
  }

  return (
    <span
      title={title}
      data-testid={`chip-lean-axiom-${leanBinding}`}
      className={`inline-flex items-center gap-1 ${padding} border border-border bg-muted font-mono text-[10px] font-bold uppercase text-muted-foreground whitespace-nowrap`}
    >
      <ShieldQuestion className={iconSize} /> Lean: unverified
    </span>
  );
}
