import tactic.induction
import data.int.basic
import data.set.basic
import logic.function.iterate

import .game

noncomputable theory
open_locale classical

lemma not_angel_hws_at_of {pw : ℕ} {s : State}
  (h : devil_hws_at pw s) : ¬angel_hws_at pw s :=
begin
  cases h with d h, change ¬∃ _, _, push_neg,
  intro a, use d, rw not_angel_wins_at, apply h,
end

lemma not_devil_hws_at_of {pw : ℕ} {s : State}
  (h : angel_hws_at pw s) : ¬devil_hws_at pw s :=
begin
  cases h with d h, change ¬∃ _, _, push_neg,
  intro a, use d, rw not_devil_wins_at, apply h,
end

-----

lemma angel_hvm_of_not_devil_hws {pw : ℕ} {s : State}
  (h : ¬devil_hws_at pw s) :
  ∀ (md : Valid_devil_move s.board),
  angel_has_valid_move pw (apply_devil_move s md.m).board :=
begin
  sorry
end

-- #exit

lemma exi_moves_hws_of_not_devil_hws {pw : ℕ} {s : State}
  (h : ¬devil_hws_at pw s) :
  ∀ (md : Valid_devil_move s.board) (d : Devil),
  ∃ (ma : Valid_angel_move pw (apply_devil_move s md.m).board) (a : Angel pw),
  (init_game a d (apply_angel_move (apply_devil_move s md.m) ma.m)).angel_wins :=
begin
  have h₁ : ¬∃ _, _ := h,
  push_neg at h₁,
  simp_rw not_devil_wins_at at h₁,
  rintro md d₁,
  let md₁ := d₁.f s,
  let d := d₁.set_move s md,
  let s' := apply_devil_move s md.m,
  change apply_devil_move s md.m with s',
  have h₂ : angel_has_valid_move pw s'.board,
  sorry,
  specialize h₁ d,
  cases h₁ with a h₁,
  let ma := a.f s' h₂,
  use [ma, a],
  have hh : d₁ = d.set_move s md₁,
  sorry,
  rw hh,
  have h₃ : (init_game a d (apply_angel_move s' ma.m)).angel_wins,
  {
    convert angel_wins_at_play_move_of h₁,
    rw init_game_play_move,
    change _ = dite _ _ _,
    have h₃ : (play_devil_move_at (init_game a d s)).s = s',
    {
      change apply_devil_move s _ = apply_devil_move s _,
      congr,
      change d.f s = md,
      sorry
    },
    sorry
    -- simp_rw h₃,
    -- rw dif_pos h₂,
    -- ext; try {refl},
    -- rw play_angel_move_at', dsimp,
    -- simp_rw h₃,
    -- change (play_devil_move_at (init_game a d s)).a with a,
    -- generalize_proofs h₄,
    -- convert_to _ = apply_angel_move s' (a.f s' h₂).m,
    -- {
    --   congr,
    --   {
    --     exact h₃,
    --   },
    --   {
    --     exact h₃,
    --   },
    --   {
    --     convert_to trivial == trivial,
    --     {
    --       exact eq_true_intro h₄,
    --     },
    --     {
    --       exact eq_true_intro h₂,
    --     },
    --     {
    --       refl,
    --     },
    --   },
    -- },
    -- refl,
  },
  sorry,
  -- let g : Game pw := _, change g.angel_wins at h₃,
  -- let g₁ : Game pw := _, change g₁.angel_wins,
  -- have h₄ : g₁ = g.set_devil (d.set_move s md₁),
  -- {
  --   sorry
  -- },
  -- rw h₄, clear h₄,
  -- have h₄ : s.history.length < (g.set_devil d).s.history.length,
  -- {
  --   change _ < (apply_angel_move _ _).history.length,
  --   exact nat.lt_succ_of_lt (nat.lt_succ_self _),
  -- },
  -- apply (devil_set_move_angel_wins_iff h₄).mpr, clear h₄,
  -- exact h₃,
end

#exit

lemma exi_angel_move_hws_of_not_devil_hws {pw : ℕ} {s : State}
  (h : ¬devil_hws_at pw s) :
  ∀ (md : Valid_devil_move s.board),
  ∃ (ma : Valid_angel_move pw (apply_devil_move s md.m).board),
  ¬devil_hws_at pw (apply_angel_move (apply_devil_move s md.m) ma.m) :=
begin
  sorry
end

def mk_angel_st_for_not_devil_hws (pw : ℕ) : Angel pw :=
begin
  refine ⟨λ s' h, _⟩,
  apply dite (∃ (s : State) (md : Valid_devil_move s.board),
    ¬devil_hws_at pw s ∧ s' = apply_devil_move s md.m); intro h₁,
  { refine (_ : ∃ (ma : Valid_angel_move pw s'.board),
      ¬devil_hws_at pw (apply_angel_move s' ma.m)).some,
    rcases h₁ with ⟨s, md, h₁, rfl⟩,
    use (exi_angel_move_hws_of_not_devil_hws h₁ _).some,
    generalize_proofs h₂, exact h₂.some_spec },
  { exact ⟨_, h.some_spec⟩ },
end

lemma not_devil_hws_at_play_of_not_devil_hws {pw n : ℕ} {g : Game pw}
  (h₁ : g.a = mk_angel_st_for_not_devil_hws pw)
  (h₂ : ¬devil_hws_at pw g.s) :
  ¬devil_hws_at pw (g.play n).s :=
begin
  rename g g₀, induction n with n ih, { exact h₂ }, clear h₂,
  rw play_at_succ', let g : Game pw := _,
  change ¬devil_hws_at pw g.s at ih,
  change ¬devil_hws_at pw g.play_move.s,
  change g.play_move with ite _ _ _,
  split_ifs, swap, { exact ih },
  let d := g.d, let s := g.s, let md := d.f s,
  let s' := apply_devil_move s md.m,
  have h₃ : ∃ (ma : Valid_angel_move pw s'.board),
    ¬devil_hws_at pw (apply_angel_move s' ma.m),
  { exact exi_angel_move_hws_of_not_devil_hws ih md },
  have ma := h₃.some, have h₄ := h₃.some_spec,
  convert h₄, change Game.s (dite _ _ _) = _,
  have h₅ : angel_has_valid_move pw s'.board := ⟨_, ma.h⟩,
  change (play_devil_move_at g).s with s',
  rw dif_pos h₅, change apply_angel_move _ _ = _, congr,
  change g.a.f s' h₅ = _, let A : Angel pw := _, change g₀.a = A at h₁,
  have h₆ : g.a = A := by { rw ←h₁, exact play_at_players_eq.1 },
  rw h₆, let p := _, change dite p _ _ = _,
  have h₇ : p := ⟨s, md, ih, rfl⟩, rw dif_pos h₇,
end

lemma angel_hws_at_of {pw : ℕ} {s : State}
  (h : ¬devil_hws_at pw s) : angel_hws_at pw s :=
begin
  let A := mk_angel_st_for_not_devil_hws pw, use A, rintro d n,
  induction n with n ih, { triv }, rw play_at_succ',
  let g : Game pw := _, change g.act at ih, change g.play_move.act,
  let s := g.s, let md := d.f s, let s' := apply_devil_move s md.m,
  rw play_move_at_act ih, have h₁ : play_devil_move_at g = g.set_state s',
  { convert play_devil_move_eq, change apply_devil_move _ (d.f s).m = _,
    congr, symmetry, exact play_at_players_eq.2 },
  rw h₁, clear h₁, have h₁ : angel_has_valid_move pw s'.board,
  { have h₁ : ¬devil_hws_at pw s := not_devil_hws_at_play_of_not_devil_hws rfl h,
    exact ⟨_, (exi_angel_move_hws_of_not_devil_hws h₁ md).some.h⟩ },
  change Game.act (dite _ _ _), change (g.set_state s').s with s',
  rw dif_pos h₁, exact ih,
end

-----

lemma devil_hws_at_of {pw : ℕ} {s : State}
  (h : ¬angel_hws_at pw s) : devil_hws_at pw s :=
by { contrapose! h, exact angel_hws_at_of h }

lemma not_angel_hws_at_iff {pw : ℕ} {s : State} :
  ¬angel_hws_at pw s ↔ devil_hws_at pw s :=
⟨devil_hws_at_of, not_angel_hws_at_of⟩

lemma not_devil_hws_at_iff {pw : ℕ} {s : State} :
  ¬devil_hws_at pw s ↔ angel_hws_at pw s :=
⟨angel_hws_at_of, not_devil_hws_at_of⟩