@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CIAP - Ativo (Base View)'
define root view entity ZR_CIAP_ATIVO
  as select from zciap_ativo
  composition [0..*] of ZR_CIAP_PARCELA as _Parcelas
{
      @EndUserText.label: 'ID do Ativo'
  key ativo_id           as AtivoId,

      @EndUserText.label: 'Descrição'
      descricao          as Descricao,

      @EndUserText.label: 'Valor Total'
      valor_total        as ValorTotal,

      @EndUserText.label: 'Valor ICMS'
      valor_icms         as ValorIcms,

      @EndUserText.label: 'Data de Aquisição'
      data_aquisicao     as DataAquisicao,

      @EndUserText.label: 'Status'
      status             as Status,

      @EndUserText.label: 'Data de Alienação'
      data_alienacao     as DataAlienacao,

      @EndUserText.label: 'Criado por'
      created_by         as CreatedBy,

      @EndUserText.label: 'Criado em'
      created_at         as CreatedAt,

      @EndUserText.label: 'Alterado por'
      last_changed_by    as LastChangedBy,

      @EndUserText.label: 'Alterado em'
      last_changed_at    as LastChangedAt,

      local_last_changed as LocalLastChanged,

      /* Associação com parcelas (composição 1:N) */
      _Parcelas
}
