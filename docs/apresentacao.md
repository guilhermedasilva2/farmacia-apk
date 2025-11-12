# Apresentação – Lembretes de Medicação

## Sumário Executivo

Implementei duas melhorias principais no fluxo de lembretes de medicação (adaptação farmacêutica das *daily goals*):

1. **Marcar como “medicação tomada”** – cada lembrete pode ser marcado como concluído, com visualização separada e persistência local.
2. **Remover lembretes com “deslizar para excluir”** – agora o usuário consegue manter a lista enxuta e remover itens obsoletos (com feedback imediato).

A tela `MedicationReminderListPage` mantém o onboarding visual (overlay, tip bubble, FAB animado) e permanece usando repositórios em memória/persistência leve, conforme o enunciado.

---

## Arquitetura (resumo)

```text
UI (MedicationReminderListPage)
  ├─ chama showMedicationReminderFormDialog -> MedicationReminderFormBloc
  │    └─ usa MedicationReminderRepository (in-memory) para criar lembretes
  ├─ lista lembretes ativos/concluídos
  │    └─ ao alternar status | remover → chama repository.upsert/delete
  └─ repository sincroniza estado em memória (ou SharedPreferences na app principal)
```

- **Fluxo de dados:** UI → Bloc/Dialog → Repository → (In-memory storage) → UI.
- **Validação:** permanece na entidade `MedicationReminder` (getter `isValid`).
- **Persistência:** página usa `InMemoryMedicationReminderRepository`; app principal continua com `SharedPreferencesMedicationReminderRepository`.

---

## Feature 1 — Marcar medicação como tomada

### Objetivo
Permitir que o usuário indique quais doses já foram administradas, oferecendo destaque visual e organização entre “pendentes” e “concluídas”.

### Exemplos de entrada/saída

| Ação                                              | Entrada (estado inicial)                 | Saída                                                         |
|--------------------------------------------------|------------------------------------------|--------------------------------------------------------------|
| Tocar em checkbox de um lembrete ativo           | `isTaken = false`                        | Lembrete vai para seção “Já administrados” com texto cinza.  |
| Desmarcar um lembrete já administrado            | `isTaken = true`                         | Lembrete volta para lista de “Próximos lembretes”.           |
| Criar novo lembrete via diálogo                  | Form preenchido (`isTaken` implícito)    | Lembrete aparece na lista de “Próximos” com checkbox desmarcada. |

### Testar localmente
1. `flutter pub get`
2. `flutter run`
3. Abrir “Lembretes de medicação” a partir da Home.
4. Adicionar um lembrete; marcar/desmarcar a caixa ao lado.
5. Conferir que o item muda de seção e mantém o estado enquanto a página está aberta.

### Limitações / Riscos
- Em memória: ao fechar a página, lembretes marcados voltam ao estado inicial (comportamento esperado nesta fase do enunciado).
- Persistência real (SharedPreferences) suportaria o campo `isTaken`, mas a interface persistente ainda não usa essa tela.
- Não há edição inline (apenas marcar/desmarcar ou remover).

---

## Feature 2 — Remover lembrete com deslizar (Swipe-to-delete)

### Objetivo
Dar ao usuário controle para excluir lembretes obsoletos e manter a lista organizada sem sobrecarga visual.

### Exemplos de entrada/saída

| Ação                               | Entrada                      | Saída                                                    |
|-----------------------------------|------------------------------|---------------------------------------------------------|
| Deslizar item para a esquerda     | Lembrete presente na lista   | Item é removido, `SnackBar` confirma remoção.           |
| Remover lembrete já administrado  | `isTaken = true`             | Item some da seção “Já administrados”.                  |
| Remover último lembrete da lista  | Lista com 1 item             | Tela volta ao estado vazio (ícone + call-to-action).    |

### Testar localmente
1. `flutter run`
2. Ir para “Lembretes de medicação”.
3. Criar dois lembretes (para testar seções).
4. Deslizar um item para apagar; observar `SnackBar`.
5. Garantir que o estado vazio reaparece se todos forem removidos.

### Limitações / Riscos
- Não há undo; remover é definitivo (em memória).
- Swipe-to-delete requer precisão; usuários com dificuldades motoras podem preferir uma ação em menu secundário (sugestão futura).
- Ausência de confirmação pode levar a exclusões acidentais (mitigável com “Desfazer” em versões futuras).

---

## Controle de Versão

- Trabalhei diretamente na branch `main` com commits atômicos e mensagens descritivas:
  - `refactor(medication): replace daily goal flow ...`
  - `feat(medication): add in-app reminder list page ...`
  - `feat(medication): list reminders on HomeScreen ...`
- Cada feature ficou isolada em um commit funcional, facilitando revisão e *rollback*.

---

## Uso de IA

- Não utilizei prompts externos nesta entrega; o desenvolvimento e a documentação foram produzidos manualmente.


