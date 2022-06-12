import tactic
import tactic.induction
import logic.function.iterate
import data.list.basic

noncomputable theory
open_locale classical

def get_some {α : Type} [inhabited α] (P : α → Prop) : α :=
if h : ∃ (x : α), P x then h.some else default

def fixed {α : Type} [inhabited α] (f : α → α) (z : α) : α :=
get_some (λ (x : α), ∃ (n : ℕ), (f^[n]) z = x ∧ (f^[n + 1]) z = x)

def all {α : Type} (P : α → Prop) (l : list α) : Prop := l.all (λ (x : α), P x)

def is_digit (n : ℕ) : Prop := n ≤ 9

def is_digit_list (l : list ℕ) : Prop := all is_digit l

def get_digits (n : ℕ) : list ℕ :=
get_some (λ (l : list ℕ), is_digit_list l ∧ l.foldl (λ (a b : ℕ), a * 10 + b) 0 = n)

def sum_digits (n : ℕ) : ℕ := (get_digits n).sum

def digital_root (n : ℕ) : ℕ := fixed sum_digits n

-----

lemma get_some_pos {α : Type} [inhabited α] {P : α → Prop}
  (h : ∃ (x : α), P x) : get_some P = h.some :=
dif_pos h

lemma get_some_eq_get_some_of_exists_iff {α β : Type} [inhabited α]
  {P₁ P₂ : α → Prop} {f : α → β}
  (h₁ : (∃ (x : α), P₁ x) ↔ (∃ (x : α), P₂ x))
  (h₂ : ∀ (h₁ : ∃ (x : α), P₁ x) (h₂ : ∃ (x : α), P₂ x), f h₁.some = f h₂.some) :
  f (get_some P₁) = f (get_some P₂) :=
begin
  simp_rw [get_some, h₁], split_ifs with h₃,
  { apply h₂ },
  { refl },
end

def reversed {α : Type} (f : list α → list α) (l : list α) : list α :=
(f l.reverse).reverse

def trim_start : list ℕ → list ℕ
| (0::l) := trim_start l
| l := l

def trim_end : list ℕ → list ℕ :=
reversed trim_start

instance {n : ℕ} : decidable (is_digit n) :=
by { rw is_digit, apply_instance }

lemma list_reverse_snoc {α : Type} {l : list α} {x : α} :
  (l ++ [x]).reverse = x :: l.reverse := list.reverse_append _ _

lemma trim_start_zero_cons {l : list ℕ} : trim_start (0 :: l) = trim_start l := rfl

lemma trim_start_succ_cons {l : list ℕ} {n : ℕ} :
  trim_start (n.succ :: l) = n.succ :: l := rfl

lemma trim_end_snoc_zero {l : list ℕ} : trim_end (l ++ [0]) = trim_end l :=
by { rw [trim_end, reversed, list_reverse_snoc, trim_start_zero_cons], refl }

lemma list_length_snoc {α : Type} {l : list α} {x : α} :
  (l ++ [x]).length = l.length + 1 := list.length_append _ _

lemma trim_end_snoc_succ {l : list ℕ} {n : ℕ} :
  trim_end (l ++ [n.succ]) = l ++ [n.succ] :=
by rw [trim_end, reversed, list_reverse_snoc, trim_start_succ_cons,
  list.reverse_cons, list.reverse_reverse]

lemma length_trim_end_le {l : list ℕ} : (trim_end l).length ≤ l.length :=
begin
  induction l using list.reverse_rec_on with l n ih,
  { refl },
  { cases n,
    { rw [trim_end_snoc_zero, list_length_snoc],
      exact nat.le_succ_of_le ih },
    { rw [trim_end_snoc_succ] }},
end

lemma list_repeat_succ_snoc {α : Type} {x : α} {n : ℕ} :
  list.repeat x n.succ = list.repeat x n ++ [x] :=
by { rw list.repeat_add x n 1, refl }

lemma trim_end_append_repeat_zero {l : list ℕ} :
  trim_end l ++ list.repeat 0 (l.length - (trim_end l).length) = l :=
begin
  induction l using list.reverse_rec_on with l n ih,
  { refl },
  { cases n,
    { rw [trim_end_snoc_zero, list_length_snoc, nat.sub_add_comm length_trim_end_le,
        list_repeat_succ_snoc, ←list.append_assoc, ih] },
    { rw [trim_end_snoc_succ, list_length_snoc, nat.sub_self,
      list.repeat, list.append_nil] }},
end

lemma all_nil {α : Type} {P : α → Prop} : all P [] := by simp [all]

lemma all_cons {α : Type} {P : α → Prop} {l : list α} {x : α} :
  all P (x :: l) ↔ P x ∧ all P l := by simp [all]

lemma all_iff {α : Type} {P : α → Prop} {l : list α} : all P l ↔ ∀ (x ∈ l), P x :=
begin
  induction l with x l ih,
  { simp [all_nil] },
  { simp [all_cons, ih] },
end

lemma all_append {α : Type} {P : α → Prop} {l₁ l₂ : list α} :
  all P (l₁ ++ l₂) ↔ all P l₁ ∧ all P l₂ :=
begin
  simp_rw all_iff, split; intro h,
  { split; rintro n h₁; apply h n,
    { exact list.mem_append_left _ h₁ },
    { exact list.mem_append_right _ h₁ }},
  { cases h with h₁ h₂, rintro n h₃, rw list.mem_append_eq at h₃, cases h₃,
    { exact h₁ _ h₃ },
    { exact h₂ _ h₃ }},
end

lemma all_singleton {α : Type} {P : α → Prop} {x : α} : all P [x] ↔ P x :=
begin
  simp_rw all_iff, split; intro h,
  { exact h _ (list.mem_singleton_self _) },
  { rintro m h₁, rw list.mem_singleton at h₁, subst m, exact h },
end

lemma all_snoc {α : Type} {P : α → Prop} {l : list α} {x : α} :
  all P (l ++ [x]) ↔ all P l ∧ P x := by rw [all_append, all_singleton]

lemma all_reverse {α : Type} {P : α → Prop} {l : list α} : all P l.reverse ↔ all P l :=
begin
  induction l with n l ih,
  { refl },
  { rw [list.reverse_cons, all_snoc, all_cons], tauto },
end

lemma is_digit_of_is_digit_add {d₁ d₂ : ℕ} (h : is_digit (d₁ + d₂)) :
  is_digit d₁ ∧ is_digit d₂ := ⟨nat.le_of_add_le_left h, nat.le_of_add_le_right h⟩

lemma not_is_digit_add_10 {n : ℕ} : ¬is_digit (n + 10) := dec_trivial

lemma is_digit_mul_10 {n : ℕ} : is_digit (n * 10) ↔ n = 0 :=
begin
  split; intro h,
  { cases n,
    { refl },
    { revert h, rw nat.succ_mul, dec_trivial }},
  { subst n, dec_trivial },
end

lemma sum_eq_zero_of_foldr_eq_zero {l : list ℕ}
  (h : l.foldr (λ (a b : ℕ), a + b * 10) 0 = 0) : l.sum = 0 :=
begin
  induction' l with hd l ih,
  { refl },
  { rw [list.foldr_cons, add_eq_zero_iff] at h, rcases h with ⟨rfl, h⟩,
    apply ih, rw mul_eq_zero at h, cases h,
    { exact h },
    { cases h }},
end

lemma sum_eq_of_foldr_eq_digit {l : list ℕ} {d : ℕ}
  (h₁ : is_digit_list l) (h₂ : is_digit d)
  (h₃ : l.foldr (λ (a b : ℕ), a + b * 10) 0 = d) : l.sum = d :=
begin
  cases l with d₁ l,
  { exact h₃ },
  { rw list.sum_cons, rw list.foldr_cons at h₃, rw [is_digit_list, all_cons] at h₁,
    cases h₁ with h₁ h₄, subst d, congr, have h₃ := (is_digit_of_is_digit_add h₂).2,
    rw is_digit_mul_10 at h₃, rw h₃, exact sum_eq_zero_of_foldr_eq_zero h₃ },
end

lemma is_digit_succ {n : ℕ} : is_digit n.succ ↔ n < 9 :=
begin
  rw [is_digit, le_iff_lt_or_eq], split; intro h,
  { cases h,
    { exact nat.lt_of_succ_lt h },
    { cases h, dec_trivial }},
  { rwa [←nat.succ_le_iff, le_iff_lt_or_eq] at h },
end

lemma nat_exi_mul (x y : ℕ) :
  ∃ (a b : ℕ), a = x / y ∧ b = x % y ∧ x = a * y + b :=
by { simp_rw mul_comm, exact ⟨_, _, rfl, rfl, (nat.div_add_mod _ _).symm⟩ }

lemma is_digit_mod_10 {n : ℕ} : is_digit (n % 10) :=
by { rw [is_digit, ←nat.lt_succ_iff], apply nat.mod_lt, dec_trivial }

lemma nat_digit_induction {P : ℕ → Prop} {n : ℕ}
  (h₁ : P 0) (h₂ : ∀ (n d : ℕ), is_digit d → P n → P (d + n * 10)) : P n :=
begin
  induction n using nat.strong_induction_on with n ih, dsimp at ih,
  obtain ⟨a, b, ha, hb, h₃⟩ := nat_exi_mul n 10, rw [h₃, add_comm], apply h₂,
  { rw hb, exact is_digit_mod_10 },
  { rw ha, cases n,
    { exact h₁ },
    { apply ih, apply nat.div_lt_self; dec_trivial }},
end

def all_zeros (l : list ℕ) : Prop := all (λ (n : ℕ), n = 0) l

lemma foldr_eq_zero_iff {l : list ℕ} :
  l.foldr (λ (a b : ℕ), a + b * 10) 0 = 0 ↔ all_zeros l :=
begin
  induction l with x l ih,
  { simp [all_zeros, all_nil] },
  { rw [list.foldr_cons, all_zeros, all_cons, ←all_zeros, ←ih,
    add_eq_zero_iff, mul_eq_zero], tauto },
end

lemma trim_end_nil : trim_end [] = [] := rfl

lemma trim_end_eq_nil_iff {l : list ℕ} : trim_end l = [] ↔ all_zeros l :=
begin
  induction l using list.reverse_rec_on with l n ih,
  { simp [trim_end_nil, all_zeros, all_nil] },
  { cases n,
    { simp [trim_end_snoc_zero, ih, all_zeros, all_snoc] },
    { simp [trim_end_snoc_succ, all_zeros, all_snoc] }},
end

lemma left_lt_of_add_lt {a b c : ℕ} (h : a + b < c) : a < c := buffer.lt_aux_1 h

lemma right_lt_of_add_lt {a b c : ℕ} (h : a + b < c) : b < c :=
by { rw add_comm at h, exact left_lt_of_add_lt h }

lemma lt_of_add_lt {a b c : ℕ} (h : a + b < c) : a < c ∧ b < c :=
⟨left_lt_of_add_lt h, right_lt_of_add_lt h⟩

lemma not_add_self_lt_self {a b : ℕ} : ¬a + b < b :=
by { intro h, cases lt_irrefl _ (right_lt_of_add_lt h) }

lemma eq_zero_of_mul_lt_self {a b : ℕ} (h : a * b < a) : b = 0 :=
begin
  cases b,
  { refl },
  { rw nat.mul_succ at h, cases not_add_self_lt_self h },
end

lemma add_mul_eq_add_mul_iff {k d₁ d₂ a b : ℕ} (h₁ : d₁ < k) (h₂ : d₂ < k) :
  d₁ + a * k = d₂ + b * k ↔ d₁ = d₂ ∧ a = b :=
begin
  split; intro h,
  { induction a with a ih generalizing b,
    { rw [zero_mul, add_zero] at h, subst d₁, have h₃ := right_lt_of_add_lt h₁,
      rw mul_comm at h₃, replace h₃ := eq_zero_of_mul_lt_self h₃, subst b,
      rw zero_mul, exact ⟨rfl, rfl⟩ },
    { rw [nat.succ_mul, ←add_assoc] at h, cases b,
      { rw [zero_mul, add_zero] at h, subst d₂, cases not_add_self_lt_self h₂ },
      { rw [nat.succ_mul, ←add_assoc, add_left_inj] at h,
        rw nat.succ_inj', exact ih h }}},
  { rw [h.1, h.2] },
end

lemma digit_lt_10 {d : ℕ} (h : is_digit d) : d < 10 := by rwa nat.lt_succ_iff

lemma digit_add_mul_10_eq_digit_add_mul_10_iff {d₁ d₂ a b : ℕ}
  (h₁ : is_digit d₁) (h₂ : is_digit d₂) :
  d₁ + a * 10 = d₂ + b * 10 ↔ d₁ = d₂ ∧ a = b :=
by { rw add_mul_eq_add_mul_iff; apply digit_lt_10; assumption }

lemma trim_end_cons {l : list ℕ} {n : ℕ} :
  trim_end (n :: l) = if all_zeros l then trim_end [n] else n :: trim_end l :=
begin
  split_ifs,
  { induction l using list.reverse_rec_on with l m ih,
    { refl },
    { rw [all_zeros, all_snoc, ←all_zeros] at h, rcases h with ⟨h, rfl⟩,
      specialize ih h, rwa [←list.cons_append, trim_end_snoc_zero] }},
  { induction l using list.reverse_rec_on with l m ih,
    { cases h all_nil },
    { rw ←list.cons_append,
      rw [all_zeros, all_snoc, ←all_zeros, not_and_distrib] at h, cases m,
      { simp_rw trim_end_snoc_zero, cases h,
        { exact ih h },
        { cases h rfl }},
      { simp_rw [trim_end_snoc_succ, list.cons_append], use rfl }}},
end

lemma trim_end_all_zeros {l : list ℕ} (h : all_zeros l) : trim_end l = [] :=
by rwa trim_end_eq_nil_iff

lemma trim_end_singleton {n : ℕ} : trim_end [n] = if n = 0 then [] else [n] :=
begin
  split_ifs,
  { subst n, refl },
  { change [n] with [] ++ [n], cases n,
    { cases h rfl },
    { rw trim_end_snoc_succ }},
end

-- #exit

lemma trim_end_same_cons_eq_iff_aux {l₁ l₂ : list ℕ} {n : ℕ}
  (h₁ : all_zeros l₁) (h₂ : ¬all_zeros l₂) :
  trim_end [n] = n :: trim_end l₂ ↔ trim_end l₁ = trim_end l₂ :=
begin
  rw trim_end_all_zeros h₁, split; intro h,
  { rw trim_end_singleton at h, split_ifs at h with h₃,
    { cases h },
    { exact h.2 }},
  { symmetry' at h, rw trim_end_eq_nil_iff at h, contradiction }
end

lemma trim_end_same_cons_eq_iff {l₁ l₂ : list ℕ} {n : ℕ} :
  trim_end (n :: l₁) = trim_end (n :: l₂) ↔ trim_end l₁ = trim_end l₂ :=
begin
  nth_rewrite 0 trim_end_cons, nth_rewrite 1 trim_end_cons, split_ifs with h₁ h₂ h₂,
  { simp [trim_end_all_zeros h₁, trim_end_all_zeros h₂] },
  { exact trim_end_same_cons_eq_iff_aux h₁ h₂ },
  { have := @trim_end_same_cons_eq_iff_aux _ _ n h₂ h₁, tauto },
  { simp }
end

lemma trim_end_eq_trim_end_of_foldr_eq_foldr {l₁ l₂ : list ℕ}
  (h₁ : is_digit_list l₁) (h₂ : is_digit_list l₂)
  (h₃ : l₁.foldr (λ (a b : ℕ), a + b * 10) 0 = l₂.foldr (λ (a b : ℕ), a + b * 10) 0) :
  trim_end l₁ = trim_end l₂ :=
begin
  induction l₁ with n l₁ ih generalizing l₂,
  { rw trim_end_nil, symmetry' at h₃ ⊢, change _ = 0 at h₃,
    rw foldr_eq_zero_iff at h₃, rwa trim_end_eq_nil_iff },
  { rw [is_digit_list, all_cons, ←is_digit_list] at h₁,
    cases h₁ with h₁ h₄, specialize @ih h₄, cases l₂ with m l₂,
    { change _ = 0 at h₃,
      rw [list.foldr_cons, add_eq_zero_iff, mul_eq_zero, foldr_eq_zero_iff] at h₃,
      rcases h₃ with ⟨rfl, h₃⟩, rw [trim_end_nil, trim_end_eq_nil_iff, all_zeros, all_cons],
      use rfl, cases h₃,
      { exact h₃ },
      { cases h₃ }},
    { rw [is_digit_list, all_cons, ←is_digit_list] at h₂, cases h₂ with h₂ h₅,
      simp_rw [list.foldr_cons, digit_add_mul_10_eq_digit_add_mul_10_iff h₁ h₂] at h₃,
      rcases h₃ with ⟨rfl, h₃⟩, rw trim_end_same_cons_eq_iff, exact ih h₅ h₃ }},
end

lemma exi_eq_append_zeros_of_foldr_eq_foldr {l₁ l₂ : list ℕ}
  (h₁ : is_digit_list l₁) (h₂ : is_digit_list l₂)
  (h₃ : l₁.foldr (λ (a b : ℕ), a + b * 10) 0 = l₂.foldr (λ (a b : ℕ), a + b * 10) 0) :
  ∃ (l : list ℕ) (n₁ n₂ : ℕ), l₁ = l ++ list.repeat 0 n₁ ∧ l₂ = l ++ list.repeat 0 n₂ :=
begin
  use [trim_end l₁, l₁.length - (trim_end l₁).length, l₂.length - (trim_end l₁).length,
    trim_end_append_repeat_zero.symm], symmetry,
  rw [(_ : trim_end l₁ = trim_end l₂), trim_end_append_repeat_zero],
  exact trim_end_eq_trim_end_of_foldr_eq_foldr h₁ h₂ h₃,
end

lemma sum_append_repeat_zero {l : list ℕ} {n : ℕ} :
  (l ++ list.repeat 0 n).sum = l.sum :=
by { rw [list.sum_append, list.sum_repeat], refl }

lemma sum_eq_sum_of_foldr_eq_foldr {l₁ l₂ : list ℕ}
  (h₁ : is_digit_list l₁) (h₂ : is_digit_list l₂)
  (h₃ : l₁.foldr (λ (a b : ℕ), a + b * 10) 0 = l₂.foldr (λ (a b : ℕ), a + b * 10) 0) :
  l₁.sum = l₂.sum :=
begin
  obtain ⟨l, n₁, n₂, rfl, rfl⟩ := exi_eq_append_zeros_of_foldr_eq_foldr h₁ h₂ h₃,
  simp_rw sum_append_repeat_zero,
end

lemma sum_eq_sum_of_foldl_eq_foldr {l₁ l₂ : list ℕ}
  (h₁ : is_digit_list l₁) (h₂ : is_digit_list l₂)
  (h₃ : l₁.foldl (λ (a b : ℕ), a * 10 + b) 0 = l₂.foldr (λ (a b : ℕ), a + b * 10) 0) :
  l₁.sum = l₂.sum :=
begin
  rw ←list.sum_reverse l₁,
  rw ←list.foldr_reverse _ _ l₁ at h₃,
  rename l₁ l,
  rw [is_digit_list, ←all_reverse, ←is_digit_list] at h₁,
  revert h₁ h₃,
  generalize : l.reverse = l₁,
  rintro h₁ h₃,
  clear l,
  replace h₃ : list.foldr (λ a b, a + b * 10) 0 l₁ = list.foldr (λ a b, a + b * 10) 0 l₂,
  { convert h₃; ext a b; rw add_comm },
  exact sum_eq_sum_of_foldr_eq_foldr h₁ h₂ h₃,
end

lemma sum_digits_def {n : ℕ} :
  sum_digits n = (get_some (λ (l : list ℕ), is_digit_list l ∧
    l.foldr (λ (a b : ℕ), a + b * 10) 0 = n)).sum :=
begin
  apply get_some_eq_get_some_of_exists_iff,
  { split; rintro ⟨l, hl, rfl⟩; use l.reverse;
    { rw list.foldl_reverse <|> rw list.foldr_reverse,
      simp_rw add_comm, rw [is_digit_list, all_reverse, ←is_digit_list], use hl }},
  { rintro h₁ h₂, have h₃ := h₁.some_spec, have h₄ := h₂.some_spec,
    have h₅ : list.foldl (λ (a b : ℕ), a * 10 + b) 0 h₁.some =
      list.foldr (λ (a b : ℕ), a + b * 10) 0 h₂.some := by rw [h₃.2, h₄.2],
    exact sum_eq_sum_of_foldl_eq_foldr h₃.1 h₄.1 h₅ },
end

lemma sum_digits_zero : sum_digits 0 = 0 :=
begin
  rw [sum_digits_def, get_some_pos], swap,
  { exact ⟨[], all_nil, rfl⟩ },
  generalize_proofs h, exact sum_eq_zero_of_foldr_eq_zero h.some_spec.2,
end

lemma iter_sum_digits_zero {n : ℕ} : (sum_digits^[n]) 0 = 0 :=
begin
  induction' n,
  { refl },
  { rw [function.iterate_succ_apply', ih, sum_digits_zero] },
end

lemma digital_root_zero : digital_root 0 = 0 :=
begin
  rw [digital_root, fixed, get_some_pos], swap,
  { exact ⟨0, 0, rfl, sum_digits_zero⟩ },
  generalize_proofs h₁, obtain ⟨n, h₂, h₃⟩ := h₁.some_spec,
  rw iter_sum_digits_zero at h₂, exact h₂.symm,
end

def modp (n k : ℕ) : ℕ := if n.mod k = 0 then k else n.mod k

lemma modp_pos_digit {d : ℕ} (h₁ : is_digit d) (h₂ : 0 < d) : modp d 9 = d :=
begin
  rw modp, split_ifs,
  { change d % 9 = 0 at h, rw [is_digit, le_iff_lt_or_eq] at h₁, cases h₁,
    { rw nat.mod_eq_of_lt h₁ at h, rw h at h₂, cases h₂ },
    { exact h₁.symm }},
  { rw [is_digit, le_iff_lt_or_eq] at h₁, cases h₁,
    { exact nat.mod_eq_of_lt h₁ },
    { subst d, contradiction }},
end

lemma sum_digits_digit {d : ℕ} (h : is_digit d) : sum_digits d = d :=
begin
  rw [sum_digits_def, get_some_pos], swap,
  { exact ⟨[d], all_singleton.mpr h, rfl⟩ },
  generalize_proofs h₁, obtain ⟨h₂, h₃⟩ := h₁.some_spec,
  exact sum_eq_of_foldr_eq_digit h₂ h h₃,
end

lemma iterate_eq_self {α : Type} {f : α → α} {x : α} {n : ℕ}
  (h : f x = x) : (f^[n] x) = x :=
begin
  induction n with n ih,
  { refl },
  { rw [function.iterate_succ_apply', ih, h] },
end

lemma fixed_eq_self_of {α : Type} [inhabited α] {f : α → α} {x : α}
  (h : f x = x) : fixed f x = x :=
begin
  rw [fixed, get_some_pos], swap,
  { exact ⟨x, 0, rfl, h⟩ },
  generalize_proofs h₁, obtain ⟨n, h₂, h₃⟩ := h₁.some_spec,
  rw [←h₂, iterate_eq_self h],
end

lemma digital_root_pos_digit_eq_self {d : ℕ} (h₁ : is_digit d) (h₂ : 0 < d) :
  digital_root d = d := fixed_eq_self_of (sum_digits_digit h₁)

lemma is_digit_modp_9 {n : ℕ} : is_digit (modp n 9) :=
begin
  rw [is_digit, modp], split_ifs,
  { refl },
  { apply le_of_lt, apply nat.mod_lt, dec_trivial },
end

lemma is_digit_digit_add_digit_sub {d₁ d₂ n : ℕ} (h₁ : is_digit d₁) (h₂ : is_digit d₂)
  (h₃ : 9 ≤ n) : is_digit (d₁ + d₂ - n) :=
begin
  rw is_digit at h₁ h₂ ⊢,
  have h₄ := (add_le_add h₁ h₂).trans (add_le_add (le_refl _) h₃),
  rwa tsub_le_iff_right,
end

lemma exi_digit_add_10_of_not_is_digit_add {d₁ d₂ : ℕ}
  (h₁ : is_digit d₁) (h₂ : is_digit d₂) (h₃ : ¬is_digit (d₁ + d₂)) :
  ∃ (d : ℕ), is_digit d ∧ d₁ + d₂ = d + 10 :=
begin
  refine ⟨d₁ + d₂ - 10, _, _⟩,
  { apply is_digit_digit_add_digit_sub h₁ h₂, dec_trivial },
  { rw [is_digit, not_le] at h₃, obtain ⟨k, h₄⟩ := nat.exists_eq_add_of_lt h₃,
    rw h₄, refine (nat.sub_eq_iff_eq_add _).mp rfl, rw add_right_comm, exact le_self_add },
end

lemma exi_digit_add_9_of_not_is_digit_add {d₁ d₂ : ℕ}
  (h₁ : is_digit d₁) (h₂ : is_digit d₂) (h₃ : ¬is_digit (d₁ + d₂)) :
  ∃ (d : ℕ), is_digit d ∧ d₁ + d₂ = d + 9 :=
begin
  refine ⟨d₁ + d₂ - 9, _, _⟩,
  { apply is_digit_digit_add_digit_sub h₁ h₂, dec_trivial },
  { rw [is_digit, not_le] at h₃, obtain ⟨k, h₄⟩ := nat.exists_eq_add_of_lt h₃,
    rw h₄, refine (nat.sub_eq_iff_eq_add _).mp rfl, apply nat.le_succ_of_le,
    exact le_self_add },
end

lemma is_digit_of_is_digit_succ {d : ℕ} (h : is_digit d.succ) : is_digit d :=
(@is_digit_of_is_digit_add d 1 h).1

lemma sum_eq_of_foldr_eq_digit_add_10 {l : list ℕ} {d : ℕ}
  (h₁ : is_digit_list l) (h₂ : is_digit d)
  (h₃ : l.foldr (λ (a b : ℕ), a + b * 10) 0 = d + 10) : l.sum = d.succ :=
begin
  cases l with d₁ l,
  { cases h₃ },
  { rw list.foldr_cons at h₃, rw [is_digit_list, all_cons, ←is_digit_list] at h₁,
    cases h₁ with h₁ h₄, nth_rewrite 1 ←one_mul 10 at h₃,
    rw digit_add_mul_10_eq_digit_add_mul_10_iff h₁ h₂ at h₃, rcases h₃ with ⟨rfl, h₃⟩,
    rw [list.sum_cons, sum_eq_of_foldr_eq_digit h₄ dec_trivial h₃] },
end

lemma sum_digits_pos_digit_add_9 {d : ℕ} (h₁ : is_digit d) (h₂ : 0 < d) :
  sum_digits (d + 9) = d :=
begin
  cases d,
  { cases h₂ },
  { rw [sum_digits_def, get_some_pos], swap,
    { refine ⟨[d, 1], _, _⟩,
      { simp_rw [is_digit_list, all_cons, all_nil],
        exact ⟨is_digit_of_is_digit_succ h₁, dec_trivial, trivial⟩ },
      { refl }},
    generalize_proofs h₃, obtain ⟨h₄, h₅⟩ := h₃.some_spec, change _ = d + 10 at h₅,
    exact sum_eq_of_foldr_eq_digit_add_10 h₄ (is_digit_of_is_digit_succ h₁) h₅ },
end

lemma pos_left_of_not_is_digit_digit_add_digit {d₁ d₂ : ℕ}
  (h₁ : is_digit d₁) (h₂ : is_digit d₂) (h₃ : ¬is_digit (d₁ + d₂)) : 0 < d₁ :=
by { rw is_digit at h₁ h₂ h₃, linarith }

lemma pos_right_of_not_is_digit_digit_add_digit {d₁ d₂ : ℕ}
  (h₁ : is_digit d₁) (h₂ : is_digit d₂) (h₃ : ¬is_digit (d₁ + d₂)) : 0 < d₂ :=
by { rw add_comm at h₃, exact pos_left_of_not_is_digit_digit_add_digit h₂ h₁ h₃ }

lemma sum_digits_digit_add_digit {d₁ d₂ : ℕ} (h₁ : is_digit d₁) (h₂ : is_digit d₂) :
  sum_digits (d₁ + d₂) = if d₁ + d₂ ≤ 9 then d₁ + d₂ else d₁ + d₂ - 9 :=
begin
  split_ifs,
  { exact sum_digits_digit h },
  { obtain ⟨d, h₃, h₄⟩ := exi_digit_add_9_of_not_is_digit_add h₁ h₂ h, have h₅ : 0 < d,
    { rw h₄ at h, push_neg at h, rwa lt_add_iff_pos_left at h },
    rw [h₄, sum_digits_pos_digit_add_9 h₃ h₅], refl },
end

lemma modp_of_le_of_pos {k d : ℕ} (h₁ : 0 < d) (h₂ : d ≤ k) : modp d k = d :=
begin
  rw modp, change d.mod k with d % k, cases k,
  { rw nat.le_zero_iff at h₂, subst d, refl },
  { split_ifs with h₃,
    { rw le_iff_lt_or_eq at h₂, cases h₂,
      { rw nat.mod_eq_of_lt h₂ at h₃, subst d, cases h₁ },
      { subst d }},
    { rw le_iff_lt_or_eq at h₂, cases h₂,
      { exact nat.mod_eq_of_lt h₂ },
      { subst d, cases h₃ (nat.mod_self _) }}},
end

lemma add_self_mod_eq_zero {a : ℕ} : (a + a) % a = 0 := by simp

lemma modp_add {k a b : ℕ} : modp (a + b) k = modp (modp a k + modp b k) k :=
by { simp_rw modp, change nat.mod with (%), split_ifs; simp [*, nat.add_mod] at * }

lemma pos_modp_of_pos {k a : ℕ} (h₁ : 0 < k) (h₂ : 0 < a) : 0 < modp a k :=
begin
  rw modp, split_ifs,
  { exact h₁ },
  { rwa pos_iff_ne_zero },
end

lemma digital_root_eq_self_of {n : ℕ} (h : sum_digits n = n) :
  digital_root n = n := fixed_eq_self_of h

-- #exit

lemma digital_root_digit_add_mul_10 {d n : ℕ} (h : is_digit d) :
  digital_root (d + n * 10) = sum_digits (d + digital_root n) :=
begin
  sorry
end

-- #exit

lemma modp_digit_add_mul_10 {d n : ℕ} (h : is_digit d) :
  modp (d + n * 10) 9 = modp (d + n) 9 :=
begin
  sorry
end

-- #exit

lemma digital_root_pos_eq_modp {n : ℕ} (h : 0 < n) : digital_root n = modp n 9 :=
begin
  induction n using nat_digit_induction with n d h₁ ih,
  {
    cases h,
  },
  {
    cases n,
    sorry { simp_rw [zero_mul, zero_add] at h ⊢,
      rw [modp_pos_digit h₁ h, digital_root_pos_digit_eq_self h₁ h] },
    {
      clear h,
      specialize ih (nat.zero_lt_succ _),
      rw [digital_root_digit_add_mul_10 h₁, modp_digit_add_mul_10 h₁, ih],
      clear ih,
      rw sum_digits_digit_add_digit h₁ is_digit_modp_9,
      split_ifs,
      {
        cases d,
        sorry {
          simp,
        },
        {
          rw [modp_add, modp_pos_digit h₁ (nat.zero_lt_succ _)],
          sorry
        },
      },
      sorry,
    },
  },
end

#exit

lemma digital_root_eq {n : ℕ} :
  digital_root n = if n = 0 then 0 else if n.mod 9 = 0 then 9 else n.mod 9 :=
begin
  rw ←modp,
  split_ifs with h h₁,
  sorry { cases h, exact digital_root_zero },
  {
    sorry
  },
end