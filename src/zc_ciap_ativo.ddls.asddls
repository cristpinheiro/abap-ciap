@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'CIAP - Projection - Ativo'

@UI.headerInfo: {
  typeName: 'Ativo',
  typeNamePlural: 'Ativos',
  title: { type: #STANDARD, value: 'Descricao' },
  description: { type: #STANDARD, value: 'AtivoId' }
}

define root view entity ZC_CIAP_ATIVO
  provider contract transactional_query
  as projection on ZR_CIAP_ATIVO
{
      @UI.facet: [
        { id: 'AtivoInfo',
          purpose: #STANDARD,
          type: #IDENTIFICATION_REFERENCE,
          label: 'Informações do Ativo',
          position: 10 },
        { id: 'ParcelasFacet',
          purpose: #STANDARD,
          type: #LINEITEM_REFERENCE,
          label: 'Parcelas',
          position: 20,
          targetElement: '_Parcelas' }
      ]

      @UI: { lineItem: [{ position: 10 }],
             identification: [{ position: 10 }],
             selectionField: [{ position: 10 }] }
  key AtivoId,

      @UI: { lineItem: [{ position: 20 }],
             identification: [{ position: 20 }] }
      Descricao,

      @UI: { lineItem: [{ position: 30 }],
             identification: [{ position: 30 }] }
      ValorTotal,

      @UI: { lineItem: [{ position: 40 }],
             identification: [{ position: 40 }] }
      ValorIcms,

      @UI: { lineItem: [{ position: 50 }],
             identification: [{ position: 50 }],
             selectionField: [{ position: 20 }] }
      DataAquisicao,

      @UI: { lineItem:       [{ position: 60 },
                               { type: #FOR_ACTION, dataAction: 'Alienar', label: 'Alienar' }],
             identification: [{ position: 60 },
                               { type: #FOR_ACTION, dataAction: 'Alienar', label: 'Alienar' }] }
      @UI.fieldGroup: [{ qualifier: 'AtivoInfo', position: 60 }]
      Status,

      @UI: { identification: [{ position: 70 }] }
      DataAlienacao,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChanged,

      /* Associação */
      _Parcelas : redirected to composition child ZC_CIAP_PARCELA
}
