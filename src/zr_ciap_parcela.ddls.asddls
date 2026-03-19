@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CIAP - Parcela (Base View)'
define view entity ZR_CIAP_PARCELA
  as select from zciap_parcela
  association to parent ZR_CIAP_ATIVO as _Ativo on $projection.AtivoId = _Ativo.AtivoId
{
      @EndUserText.label: 'ID do Ativo'
  key ativo_id         as AtivoId,

      @EndUserText.label: 'Número da Parcela'
  key parcela_num      as ParcelaNum,

      @EndUserText.label: 'Mês de Referência'
      mes_referencia   as MesReferencia,

      @EndUserText.label: 'Valor da Parcela'
      valor_parcela    as ValorParcela,

      @EndUserText.label: 'Status da Parcela'
      status           as Status,

      @EndUserText.label: 'Data de Apropriação'
      data_apropriacao as DataApropriacao,

      /* Associação com o ativo pai */
      _Ativo
}
