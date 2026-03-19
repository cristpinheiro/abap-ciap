# Projeto CIAP — Controle de Crédito ICMS sobre Ativo Imobilizado

> **Ambiente:** SAP BTP ABAP Environment (Trial ou licenciado)
> **Stack:** ABAP Cloud · RAP (managed) · CDS View Entities · OData V4 · Fiori Elements
> **Objetivo:** Praticar ABAP moderno construindo um sistema funcional que simula o controle de CIAP — o mesmo domínio de negócio do time Global Financial Brazil.

---

## 1. Contexto de Negócio

### O que é CIAP?

CIAP = **Crédito de ICMS do Ativo Permanente**.

Quando uma empresa compra um **bem do ativo imobilizado** (máquina, equipamento, veículo) para usar na produção, ela paga ICMS na compra. A legislação brasileira permite que a empresa **recupere esse ICMS** em **48 parcelas mensais** iguais (1/48 por mês).

### Regras principais

| Regra | Descrição |
|---|---|
| **Parcelas** | O crédito é dividido em 48 parcelas iguais (valor ICMS ÷ 48) |
| **Início** | A primeira parcela é no mês seguinte à aquisição |
| **Apropriação** | Todo mês a empresa "apropria" (recupera) uma parcela |
| **Alienação** | Se o ativo for vendido/descartado antes de 48 meses, as parcelas restantes são **perdidas** |
| **Encerramento** | Após 48 parcelas apropriadas, o controle do ativo é encerrado |

### Por que isso importa?

- Empresas grandes têm **centenas de ativos** com parcelas em andamento
- Erros geram **multas fiscais** (SPED Bloco G)
- O time TDF/CIAP da SAP automatiza esse controle dentro do ERP
- Você está construindo uma versão simplificada para aprender o domínio e praticar ABAP

---

## 2. O que o Sistema Faz

### Funcionalidades

| # | Funcionalidade | Descrição |
|---|---|---|
| 1 | **Cadastrar ativo** | Registrar um bem comprado com valor total, valor ICMS e data de aquisição |
| 2 | **Gerar parcelas automaticamente** | Ao cadastrar, o sistema cria 48 registros de parcela (determinação RAP) |
| 3 | **Consultar ativos** | Listar todos os ativos com status, valor total, ICMS, parcelas apropriadas/pendentes |
| 4 | **Consultar parcelas** | Ver parcelas de um ativo específico ou de todos os ativos por período |
| 5 | **Apropriar parcela** | Marcar que o crédito de um mês foi recuperado (action RAP) |
| 6 | **Alienar ativo** | Registrar venda/descarte antes de 48 meses — cancela parcelas pendentes (action RAP) |
| 7 | **Validações** | ICMS não pode ser maior que o valor total; data de aquisição não pode ser futura; campos obrigatórios |

### Interface

- **API OData V4** gerada automaticamente pelo RAP (testável via Postman, curl, browser)
- **Fiori Elements** gerado por anotações CDS (lista de ativos + detalhe com parcelas)

---

## 3. Exemplos de Uso

### Exemplo 1 — Cadastro de ativo

```
Entrada:
  Descrição:      "Torno CNC Modelo X"
  Valor Total:     R$ 100.000,00
  Valor ICMS:      R$ 18.000,00
  Data Aquisição:  2026-03-15

Resultado automático:
  → Ativo criado com ID 001, Status = "EM ANDAMENTO"
  → 48 parcelas geradas:
    Parcela 01: Mês 2026-04, Valor R$ 375,00, Status PENDENTE
    Parcela 02: Mês 2026-05, Valor R$ 375,00, Status PENDENTE
    ...
    Parcela 48: Mês 2030-03, Valor R$ 375,00, Status PENDENTE
```

### Exemplo 2 — Consulta de crédito mensal

```
Consulta: "Quanto de crédito ICMS tenho para apropriar em 04/2026?"

Resultado:
  Ativo 001 - Torno CNC:       R$ 375,00
  Ativo 002 - Empilhadeira:    R$ 125,00
  ─────────────────────────────────────
  Total do mês:                 R$ 500,00
```

### Exemplo 3 — Apropriar parcela

```
Ação: Apropriar parcelas do mês 2026-04

Resultado:
  Parcela 01 do Ativo 001: PENDENTE → APROPRIADA
  Parcela 01 do Ativo 002: PENDENTE → APROPRIADA
```

### Exemplo 4 — Alienar ativo

```
Ação: Alienar Ativo 002 (vendido em 2026-10)

Resultado:
  → 6 parcelas já apropriadas (04 a 09/2026): mantidas
  → 42 parcelas restantes: Status = CANCELADA
  → Ativo 002: Status = "ALIENADO"
  → Crédito perdido: 42 × R$ 125,00 = R$ 5.250,00
```

---

## 4. Arquitetura Técnica

### 4.1 Modelo de Dados (Tabelas)

```
┌─────────────────────┐       ┌─────────────────────────┐
│   ZCIAP_ATIVO       │       │   ZCIAP_PARCELA         │
│─────────────────────│       │─────────────────────────│
│ * ativo_id (key)    │──1:N──│ * ativo_id (key, FK)    │
│   descricao         │       │ * parcela_num (key)     │
│   valor_total       │       │   mes_referencia        │
│   valor_icms        │       │   valor_parcela         │
│   data_aquisicao    │       │   status                │
│   status            │       │   data_apropriacao      │
│   data_alienacao    │       └─────────────────────────┘
│   created_by        │
│   created_at        │
│   last_changed_by   │
│   last_changed_at   │
└─────────────────────┘
```

**Valores de status do ativo:** `EM_ANDAMENTO`, `ENCERRADO`, `ALIENADO`
**Valores de status da parcela:** `PENDENTE`, `APROPRIADA`, `CANCELADA`

### 4.2 CDS View Entities

| CDS View | Tipo | Descrição |
|---|---|---|
| `ZR_CIAP_ATIVO` | Base (R_) | View sobre ZCIAP_ATIVO com associação para parcelas |
| `ZR_CIAP_PARCELA` | Base (R_) | View sobre ZCIAP_PARCELA com associação para ativo |
| `ZC_CIAP_ATIVO` | Projection (C_) | Projeção do ativo para o serviço OData/Fiori |
| `ZC_CIAP_PARCELA` | Projection (C_) | Projeção da parcela para o serviço OData/Fiori |

### 4.3 Behavior Definition

```
managed implementation in class ZBP_R_CIAP_ATIVO unique;

define behavior for ZR_CIAP_ATIVO alias Ativo
  persistent table zciap_ativo
{
  create;
  update;
  delete;

  // Gera 48 parcelas ao criar o ativo
  determination GerarParcelas on modify { create; }

  // Validações
  validation ValidarICMS   on save { create; update; field ValorICMS; }
  validation ValidarData   on save { create; update; field DataAquisicao; }

  // Actions
  action Alienar result [1] $self;

  // Composição com parcelas
  association _Parcelas { create; }
}

define behavior for ZR_CIAP_PARCELA alias Parcela
  persistent table zciap_parcela
{
  update;

  // Action para apropriar
  action Apropriar result [1] $self;

  // Associação com ativo (pai)
  association _Ativo;
}
```

### 4.4 Service Definition e Binding

| Objeto | Nome | Descrição |
|---|---|---|
| Service Definition | `ZCIAP_SD` | Expõe as CDS Projection Views |
| Service Binding | `ZCIAP_SB` | Tipo OData V4 - UI, publica o serviço |

### 4.5 Stack Completo

```
Tabelas DB ──→ CDS Views (R_) ──→ Behavior Definition ──→ CDS Projections (C_)
                                                                    │
                                                          Service Definition
                                                                    │
                                                          Service Binding (OData V4)
                                                                    │
                                                    ┌───────────────┼───────────────┐
                                                    │               │               │
                                              Fiori Elements    Postman/curl    EML (ABAP)
```

---

## 5. Ordem de Implementação

O projeto é dividido em **7 fases incrementais**. Cada fase produz algo funcional que pode ser testado antes de avançar.

---

### Fase 1 — Tabelas e CDS Views base

> 📄 **Documentação:** [`projeto_ciap_fase1.md`](projeto_ciap_fase1.md)

**O que fazer:**
- Criar as tabelas de banco de dados `ZCIAP_ATIVO` e `ZCIAP_PARCELA`
- Criar as CDS View Entities base (`ZR_CIAP_ATIVO` e `ZR_CIAP_PARCELA`)
- Definir associações entre ativo e parcela (composição 1:N)
- Testar com Data Preview (`F8`) — inserir dados manualmente se necessário

**Conceitos ABAP praticados:**
- `DEFINE TABLE` (DDL)
- `DEFINE VIEW ENTITY` com `association`
- Tipos de dados, chaves primárias, campos de controle administrativo

**Critério de conclusão:** Consegue abrir Data Preview nas CDS Views e ver a estrutura (mesmo sem dados).

---

### Fase 2 — Behavior Definition + CRUD básico

> 📄 **Documentação:** [`fase2_documentacao.md`](fase2_documentacao.md)

**O que fazer:**
- Criar a Behavior Definition para `ZR_CIAP_ATIVO` (managed, com `create`, `update`, `delete`)
- Criar a Behavior Definition para `ZR_CIAP_PARCELA` (managed, com `update`)
- Criar as CDS Projection Views (`ZC_CIAP_ATIVO` e `ZC_CIAP_PARCELA`)
- Criar a Behavior Projection
- Criar o Service Definition e o Service Binding
- Publicar e testar o serviço OData — criar/editar/deletar ativos via Preview

**Conceitos ABAP praticados:**
- RAP managed scenario
- Behavior Definition syntax
- CDS Projection Views (`as projection on`)
- Service Definition / Service Binding
- Testar OData via browser/Fiori Preview

**Critério de conclusão:** Consegue criar um ativo pelo Fiori Elements Preview e ele aparece na lista.

---

### Fase 3 — Determinação (gerar parcelas automaticamente)

> 📄 **Documentação:** [`projeto_ciap_fase3.md`](projeto_ciap_fase3.md)

**O que fazer:**
- Implementar a determinação `GerarParcelas` na behavior implementation class
- Ao criar um ativo, calcular `valor_icms / 48` e gerar 48 registros na tabela de parcelas
- Cada parcela com mês de referência incrementando a partir do mês seguinte à aquisição
- Testar: criar um ativo e verificar que 48 parcelas foram geradas

**Conceitos ABAP praticados:**
- `determination ... on modify { create; }`
- EML interno (`MODIFY ENTITIES ... CREATE` para criar parcelas filhas)
- Cálculos com datas (adicionar meses)
- Internal tables e loops

**Critério de conclusão:** Ao criar um ativo com ICMS de R$ 4.800, o sistema gera 48 parcelas de R$ 100 cada.

---

### Fase 4 — Validações

> 📄 **Documentação:** [`fase4_documentacao.md`](fase4_documentacao.md)

**O que fazer:**
- Implementar `ValidarICMS`: valor ICMS não pode ser maior que valor total, nem zero/negativo
- Implementar `ValidarData`: data de aquisição não pode ser no futuro
- Validação de campos obrigatórios (descrição, valor total, valor ICMS, data)
- Testar: tentar criar ativo com dados inválidos e verificar que o erro aparece

**Conceitos ABAP praticados:**
- `validation ... on save { create; update; field ...; }`
- `RAISE EXCEPTION` / mensagens de erro no RAP (`APPEND VALUE #( ... ) TO reported-...`)
- `failed` e `reported` tables

**Critério de conclusão:** Criar um ativo com ICMS > valor total retorna erro e não salva.

---

### Fase 5 — Actions (Apropriar e Alienar)

> 📄 **Documentação:** [`fase5_documentacao.md`](fase5_documentacao.md)

**O que fazer:**
- Implementar action `Apropriar` na parcela: muda status de PENDENTE para APROPRIADA, registra data
- Implementar action `Alienar` no ativo: muda status para ALIENADO, cancela todas as parcelas PENDENTES restantes, registra data de alienação
- Adicionar lógica: não permitir apropriar parcela já apropriada; não permitir alienar ativo já alienado/encerrado
- Adicionar anotações UI (`@UI.lineItem`, `@UI.identification`) para que as actions apareçam como botões no Fiori Elements

**Conceitos ABAP praticados:**
- `action ... result [1] $self`
- EML interno para atualizar registros relacionados
- Anotações CDS para UI (`@UI`)
- Lógica condicional e tratamento de erros em actions

**Critério de conclusão:** No Fiori Elements, clicar "Apropriar" numa parcela muda o status; clicar "Alienar" num ativo cancela as parcelas restantes.

---

### Fase 6 — Consulta de Crédito a Receber por Mês/Ano

> 📄 **Documentação:** [`fase6_documentacao.md`](fase6_documentacao.md)

**O que fazer:**
- Criar CDS View Entity `ZR_CIAP_CREDITO_MENSAL` que agrupa parcelas **pendentes** por `mes_referencia`
- Usar `SUM(valor_parcela)` para totalizar o crédito a receber por mês e `COUNT(*)` para quantidade de parcelas
- Criar CDS Projection `ZC_CIAP_CREDITO_MENSAL` com anotações `@UI` para exibição como lista
- Expor a nova view no Service Definition e Service Binding existentes
- Testar: verificar que a listagem mostra mês/ano, total de crédito pendente e quantidade de parcelas

**Conceitos ABAP praticados:**
- CDS View Entity com funções de agregação (`SUM`, `COUNT`)
- `GROUP BY` em CDS Views
- Filtros em CDS (`WHERE status = 'PENDENTE'`)
- Anotações `@UI` para list report
- Reutilização de Service Definition/Binding existente

**Exemplo de resultado esperado:**

```
Consulta: Crédito a receber por mês

Mês/Ano     | Crédito a Receber | Qtd Parcelas
──────────────────────────────────────────────
2026-04      | R$ 500,00         | 4
2026-05      | R$ 500,00         | 4
2026-06      | R$ 500,00         | 4
...
2030-03      | R$ 375,00         | 1
```

**Critério de conclusão:** No Fiori Elements Preview, a listagem de crédito mensal aparece com mês/ano, valor total e quantidade de parcelas pendentes agrupados corretamente.

---

### Fase 7 — Testes Unitários ABAP

> 📄 **Documentação:** [`fase7_documentacao.md`](fase7_documentacao.md)

**O que fazer:**
- Criar classe de teste para **validações**: testar que ICMS > valor total retorna erro, data futura retorna erro, campos obrigatórios vazios retornam erro
- Criar classe de teste para **determinação** (`GerarParcelas`): testar que ao criar um ativo, 48 parcelas são geradas com valores corretos e meses de referência incrementais
- Criar classe de teste para **actions** (`Apropriar` e `Alienar`): testar que apropriar muda status da parcela, alienar cancela parcelas pendentes e muda status do ativo
- Adicionar cenários negativos: apropriar parcela já apropriada deve falhar, alienar ativo já alienado deve falhar

**Conceitos ABAP praticados:**
- Classes de teste ABAP (`FOR TESTING`, `RISK LEVEL HARMLESS`, `DURATION SHORT`)
- `CL_ABAP_UNIT_ASSERT` (`assert_equals`, `assert_not_initial`, `assert_initial`, `fail`)
- EML em contexto de teste (criar/ler/modificar entidades via `MODIFY ENTITIES` e `READ ENTITIES`)
- Padrão **Given-When-Then** para organização dos métodos de teste
- Execução da suite de testes via ADT (Ctrl+Shift+F10)

**Exemplo de cenários de teste:**

```
Teste: ValidarICMS_DeveRejeitarICMSMaiorQueTotal
  Given: Ativo com valor_total = 100, valor_icms = 150
  When:  CREATE via EML
  Then:  failed table não está vazia, reported contém mensagem de erro

Teste: GerarParcelas_DeveCriar48Parcelas
  Given: Ativo com valor_icms = 4800, data_aquisicao = 2026-03-15
  When:  CREATE via EML (dispara determinação)
  Then:  READ parcelas → 48 registros, cada um com valor = 100

Teste: Apropriar_DeveAlterarStatusParaApropriada
  Given: Parcela com status = PENDENTE
  When:  Executar action Apropriar
  Then:  status = APROPRIADA, data_apropriacao preenchida

Teste: Alienar_DeveCancelarParcelasPendentes
  Given: Ativo com 48 parcelas, 6 apropriadas, 42 pendentes
  When:  Executar action Alienar
  Then:  Ativo status = ALIENADO, 42 parcelas com status = CANCELADA
```

**Critério de conclusão:** Todos os testes passam (barra verde) ao executar a suite de testes no ADT.

---

## 6. Extensões Futuras (opcionais)

Após completar as 7 fases, você pode estender o projeto conforme o roteiro de estudo:

| Extensão | Fase do Roteiro | O que agrega |
|---|---|---|
| Dashboard com CDS `@Analytics` | Fase 3-4 | KPIs: crédito total a apropriar, ativos em risco, histórico mensal |
| Validação de encerramento automático | Fase 3 | Quando a 48ª parcela é apropriada, mudar status do ativo para ENCERRADO |
| Relatório de crédito perdido | Fase 2-3 | Listar ativos alienados com total de crédito cancelado |

---

## 7. Glossário Rápido

| Termo | Significado |
|---|---|
| **ICMS** | Imposto estadual sobre circulação de mercadorias |
| **CIAP** | Controle de crédito de ICMS sobre ativo permanente |
| **Ativo imobilizado** | Bem de uso da empresa (máquina, veículo, equipamento) |
| **Apropriação** | Ato de recuperar uma parcela mensal do crédito de ICMS |
| **Alienação** | Venda ou descarte de um ativo antes de completar 48 meses |
| **RAP** | ABAP RESTful Application Programming Model — framework para construir BOs |
| **EML** | Entity Manipulation Language — statements ABAP para CRUD em BOs |
| **Behavior Definition** | Objeto que declara operações, validações, determinações e actions de um BO |
| **CDS View Entity** | Definição de modelo de dados reutilizável em ABAP |
| **Service Binding** | Publicação do serviço OData (gera a API REST) |
| **Fiori Elements** | Framework SAP que gera UI automaticamente a partir de anotações CDS |

---

## 8. Prompt de Contexto para IA

> Se você iniciar uma nova conversa com uma IA para pedir ajuda no projeto, cole o conteúdo deste documento e adicione:
>
> *"Estou implementando a Fase X deste projeto no SAP BTP ABAP Environment usando ADT (Eclipse). Preciso de ajuda com [descreva o que está fazendo]. Meu nível é iniciante em ABAP — completei o curso Acquiring Core ABAP Skills."*

Isso dará contexto suficiente para qualquer IA te ajudar de forma precisa.