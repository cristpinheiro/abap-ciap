@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'CIAP - Projection - Parcela'
define view entity ZC_CIAP_PARCELA
  as projection on ZR_CIAP_PARCELA
{
      @UI.lineItem: [{ position: 10 }]
  key AtivoId,

      @UI.lineItem: [{ position: 20 }]
  key ParcelaNum,

      @UI.lineItem: [{ position: 30 }]
      MesReferencia,

      @UI.lineItem: [{ position: 40 }]
      ValorParcela,

      @UI: { lineItem: [{ position: 50 },
                    { type: #FOR_ACTION, dataAction: 'Apropriar', label: 'Apropriar' }] }
      Status,

      @UI.lineItem: [{ position: 60 }]
      DataApropriacao,

      /* Associação */
      _Ativo : redirected to parent ZC_CIAP_ATIVO
}
