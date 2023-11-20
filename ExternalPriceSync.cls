global with sharing class ExternalPriceSync implements vlocity_cmt.VlocityOpenInterface {

    // Identifies if the context is running based on the QuoteToOpportunitySync
    public static boolean isIglooSyncRunning = false;
    public String cartId;

    global Boolean invokeMethod(String methodName,
                                Map<String, Object> input,
                                Map<String, Object> output,
                                Map<String, Object> options)
    { 
        if (methodName == 'GetMatrixPrice')
        {
            Object jsonObject = (Object)input.get('jsonResponse');
            Boolean isEdit = (Boolean)input.get('isEdit');
            String SalesQuoteId = (String)input.get('SalesQuoteId');
            String ContractTerm = (String)input.get('ContractTerm');
            getAccessPricing((String)input.get('cartId'),jsonObject,isEdit,SalesQuoteId,ContractTerm);
           

        }
        return true;
    }

    private void getAccessPricing(String quoteId, Object jsonResponse, Boolean isEdit, String SalesQuoteId, String ContractTerm){

        try{
        Map<String, object> extSvcInput = new Map<String, object>();
        Map<String, object> extSvcOutput = new Map<String, object>();
        Map<String, object> extSvcOptions = new Map<String, object>();

        List<Object> procResult = new List<Object>();
        List<Object> timePlanPolicyList = new List<Object>();
        List<String> qlineIds = new List<String>();

        String procedureName = 'SourceTargetAttributePricingProcedure';
        //check point 1
        Map<String, String> varCodeToFieldMap = new Map<String, String>{
            'REC_MNTH_STD_PRC'=>'vlocity_cmt__RecurringCharge__c',
            'OT_STD_PRC'=>'vlocity_cmt__OneTimeCharge__c',
            'USAGE_STD_PRC'=>'vlocity_cmt__UsageUnitPrice__c',
            'BASE_OT_STD_PRC'=>'vlocity_cmt__BaseOneTimeCharge__c',
            'BASE_REC_MNTH_STD_PRC' => 'vlocity_cmt__BaseRecurringCharge__c',
            'BASE_USAGE_STD_PRC' => 'Original_Usage__c'
        };

        Boolean createAdjustment = false;

        //check point 2
        SObject parent = [Select Id,Pricebook2Id,AccountId,CreatedDate,vlocity_cmt__DefaultCurrencyPaymentMode__c,
                            vlocity_cmt__EffectiveRecurringTotal__c,vlocity_cmt__EffectiveOneTimeTotal__c,
                            vlocity_cmt__PriceListId__c,RecordTypeId from Quote where Id =: quoteId ];

        List<SObject> itemList = [Select Id,ListPrice,PricebookEntryId,Product2Id,Quantity,
                                QuoteId,UnitPrice,vlocity_cmt__Action__c,vlocity_cmt__AssetReferenceId__c,
                                vlocity_cmt__AttributeMetadataChanges__c,vlocity_cmt__AttributeSelectedValues__c,
                                vlocity_cmt__BillingAccountId__c,vlocity_cmt__CatalogItemReferenceDateTime__c,
                                vlocity_cmt__CurrencyPaymentMode__c,vlocity_cmt__EffectiveOneTimeTotal__c,
                                vlocity_cmt__EffectiveRecurringTotal__c,vlocity_cmt__LineNumber__c,
                                vlocity_cmt__OneTimeCalculatedPrice__c,vlocity_cmt__OneTimeCharge__c,
                                vlocity_cmt__OneTimeManualDiscount__c,vlocity_cmt__OneTimeTotal__c,
                                vlocity_cmt__ParentItemId__c,vlocity_cmt__PricingLogData__c,vlocity_cmt__Product2Id__c,
                                vlocity_cmt__ProductGroupKey__c,vlocity_cmt__ProductHierarchyGroupKeyPath__c,
                                vlocity_cmt__ProductHierarchyPath__c,vlocity_cmt__ProvisioningStatus__c,
                                vlocity_cmt__ServiceAccountId__c,vlocity_cmt__RecurringCalculatedPrice__c,
                                vlocity_cmt__RecurringCharge__c,vlocity_cmt__RecurringManualDiscount__c,
                                vlocity_cmt__RecurringTotal__c,vlocity_cmt__RootItemId__c,Access_Architecture__c,
                                Access_Interconnect_Technology__c,Access_Tail__c,Access_Technology__c,Access_Transport__c,
                                Ethernet_Token_Id__c from QuoteLineItem
                                WHERE Product2.ProductCode =: 'PRD_ACCESS' AND QuoteId = : quoteId];
        
        //check point 3
        vlocity_cmt__PricingVariable__c pVariable = [Select Id from vlocity_cmt__PricingVariable__c where vlocity_cmt__AdjustmentMethod__c = 'Percent' AND 
                                vlocity_cmt__Aggregation__c = 'Unit' AND vlocity_cmt__ChargeType__c = 'Adjustment' AND
                                vlocity_cmt__CurrencyType__c = 'Currency' AND vlocity_cmt__IsActive__c = true AND
                                vlocity_cmt__RecurringFrequency__c = 'Monthly' AND vlocity_cmt__Scope__c='Line' AND
                                vlocity_cmt__SubType__c = 'Standard' AND vlocity_cmt__Type__c = 'Price' AND 
                                vlocity_cmt__ValueType__c = 'Pricing Element' LIMIT 1];

        List<vlocity_cmt__QuotePricingAdjustment__c> quotePriceADJList = new List<vlocity_cmt__QuotePricingAdjustment__c>();
        Map<String,Object> newProcResultMap = new Map<String,Object>();
        
        //check point 4
        ParseExtResponse responseList = ParseExtResponse.parse(JSON.serialize(jsonResponse));

        //check point 5
        Double discountPercent = responseList.bandWidthQuote.discountPercentage;
        Double baseMRCUsd = responseList.bandWidthQuote.accessSupplier.node.contractTerm.baseMonthlyPriceUsd;
        Double discountedMRCUsd = responseList.bandWidthQuote.accessSupplier.node.contractTerm.monthlyPriceUsd;
        Double oneTimePriceUsd = responseList.bandWidthQuote.accessSupplier.node.contractTerm.oneTimePriceUsd;
        String vendorName = responseList.bandWidthQuote.accessSupplier.supplierName;
        String accessArchitecture = responseList.bandWidthQuote.ProductDesignDetails.accessArchitecture;
        String accessTransport = responseList.bandWidthQuote.ProductDesignDetails.accessTransport;
        String accessTechnology = responseList.bandWidthQuote.ProductDesignDetails.accessTechnology;
        String accessTail = responseList.bandWidthQuote.ProductDesignDetails.accessTail;
        String accessInterconnectTechnology = responseList.bandWidthQuote.ProductDesignDetails.accessInterconnectTechnology;
        String ethernetTokenId = responseList.bandWidthQuote.ethernetTokenId;

        Integer counter = 1;
        //check point 6
        for(SObject qLines : itemList){ 

            //check point 7
            // Forming Object for repricing
            newProcResultMap.put('ID',qLines.get('Id'));
            newProcResultMap.put('AttributePricingMatrix__MRC',baseMRCUsd);
            newProcResultMap.put('AttributePricingMatrix__NRC',oneTimePriceUsd);
            newProcResultMap.put('AttributePricingMatrix__Usage',oneTimePriceUsd);
            newProcResultMap.put('OT_STD_PRC',oneTimePriceUsd);
            newProcResultMap.put('REC_MNTH_STD_PRC',baseMRCUsd);
            newProcResultMap.put('USAGE_STD_PRC',0.0);
            newProcResultMap.put('BASE_OT_STD_PRC',oneTimePriceUsd);
            newProcResultMap.put('BASE_REC_MNTH_STD_PRC',baseMRCUsd);
            newProcResultMap.put('BASE_USAGE_STD_PRC',0.0);

            procResult.add((Object)newProcResultMap);
            //Creating quote pricing record for discounting
            //check point 8    
            if(isEdit){
                List<vlocity_cmt__QuotePricingAdjustment__c> quotePriceRec = [Select Id, Name, vlocity_cmt__QuoteId__c,vlocity_cmt__AdjustmentValue__c,
                                                                                vlocity_cmt__QuoteItemId__c from vlocity_cmt__QuotePricingAdjustment__c 
                                                                                WHERE vlocity_cmt__QuoteId__c =: quoteId 
                                                                                AND vlocity_cmt__QuoteItemId__c =:  qLines.Id LIMIT 1];
                if(!quotePriceRec.isEmpty()){
                    quotePriceRec[0].vlocity_cmt__AdjustmentValue__c = -discountPercent;
                    quotePriceADJList.add(quotePriceRec[0]);
                }else{
                    vlocity_cmt__QuotePricingAdjustment__c quotePriceAd = new vlocity_cmt__QuotePricingAdjustment__c();
                    quotePriceAd.Name = vendorName;
                    quotePriceAd.vlocity_cmt__Action__c = 'Add';
                    quotePriceAd.vlocity_cmt__AddedByUserId__c = UserInfo.getUserId();
                    quotePriceAd.vlocity_cmt__AdjustmentValue__c = -discountPercent;
                    quotePriceAd.vlocity_cmt__PricingVariableId__c = pVariable.Id;
                    quotePriceAd.vlocity_cmt__QuoteId__c = quoteId;
                    quotePriceAd.vlocity_cmt__QuoteItemId__c = qLines.Id;
                    quotePriceAd.vlocity_cmt__Sequence__c = counter;
                    quotePriceAd.vlocity_cmt__Source__c = 'Agent';
                    quotePriceADJList.add(quotePriceAd);
                }
            }else{
                vlocity_cmt__QuotePricingAdjustment__c quotePriceAd = new vlocity_cmt__QuotePricingAdjustment__c();
                quotePriceAd.Name = vendorName;
                quotePriceAd.vlocity_cmt__Action__c = 'Add';
                quotePriceAd.vlocity_cmt__AddedByUserId__c = UserInfo.getUserId();
                quotePriceAd.vlocity_cmt__AdjustmentValue__c = -discountPercent;
                quotePriceAd.vlocity_cmt__PricingVariableId__c = pVariable.Id;
                quotePriceAd.vlocity_cmt__QuoteId__c = quoteId;
                quotePriceAd.vlocity_cmt__QuoteItemId__c = qLines.Id;
                quotePriceAd.vlocity_cmt__Sequence__c = counter;
                quotePriceAd.vlocity_cmt__Source__c = 'Agent';
                quotePriceADJList.add(quotePriceAd);
            }
            counter++;

            qlineIds.add((String)qLines.get('Id'));

        }

        //update itemList;
        upsert quotePriceADJList;

        extSvcInput.put('parent', parent);
        extSvcInput.put('itemList', itemList);
        extSvcInput.put('externalPriceData', procResult);
        extSvcInput.put('pricingVariableToFieldMap', varCodeToFieldMap);
        extSvcInput.put('priceDetailMessage', 'Priced from ' + procedureName);
        extSvcInput.put('timePlanPolicyList', timePlanPolicyList);
        extSvcInput.put('CreateAdjustment', createAdjustment);
        extSvcInput.put('quoteLineIds', qlineIds);
        extSvcInput.put('ContractTerm', ContractTerm);
        extSvcInput.put('SalesQuoteId', SalesQuoteId);
        extSvcInput.put('WorkingCartId', quoteId);
        setExternalPrice(extSvcInput, extSvcOutput, extSvcOptions);
        
        }catch(Exception e){
            System.debug('Exception :: '+e);
        }
    }

    public void setExternalPrice(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)
    {
        try{
        Map<String, Object> itemFields = new Map<String, Object>();
        SObject parent = (SObject)input.get('parent');
        List<SObject> itemList = (List<SObject>)input.get('itemList');
        List<Object> extPriceData = (List<Object>)input.get('externalPriceData');
        Map<String, String> fieldMap = (Map<String, String>)input.get('pricingVariableToFieldMap');
        List<Object> timePlanPolicyList = (List<Object>)input.get('timePlanPolicyList');
        String message = (String)input.get('priceDetailMessage');
        Boolean createAdjustment = (Boolean)input.get('CreateAdjustment');
        Map<String, Id> unitOfMeasureToIdMap = (Map<String, Id>) input.get('unitOfMeasureToIdMap');
        Map<Id, String> lineItemIdToUOM = new Map<Id, String>();
        
        if(extPriceData != null)
        {
            for (Object obj : extPriceData)
            {
                if (obj instanceOf Map<String, Object>)
                {
                    Map<String, Object> matrixResultRow = (Map<String, Object>)obj;
                    Map<String, Object> itemFieldDetails = new Map<String, Object>();
                    for (String fld : fieldMap.keySet())
                    {
                        String itemField = fieldMap.get(fld);
                        Map<String, Object> fieldVals = new Map<String, Object>();
                        fieldVals.put('value', matrixResultRow.get(fld));
                        fieldVals.put('detail', message);
                        itemFieldDetails.put(itemField, fieldVals);
                    }
                    itemFields.put(String.valueOf(matrixResultRow.get('ID')), itemFieldDetails);

                     //only for UOM
                    String uom = String.valueOf(matrixResultRow.get('UOM'));
                    if(String.isNotBlank(uom))
                    {
                        lineItemIdToUOM.put((Id)matrixResultRow.get('ID'), uom);
                    }
                }
            }
            //System.debug('itemFields: ' + JSON.serialize(itemFields));
            
        }
        
        if (!itemFields.isEmpty() || createAdjustment)
        {
            Type t = Type.forName('vlocity_cmt.SetCartItemExternalPriceService');
            if (t != null)
            {
                vlocity_cmt.VlocityOpenInterface externalPriceService = (vlocity_cmt.VlocityOpenInterface)t.newInstance();
                Map<String, Object> externalPriceServiceInput = new Map<String, Object>();
                Map<String, Object> externalPriceServiceOutput = new Map<String, Object>();
                Map<String, Object> externalPriceServiceOptions = new Map<String, Object>();
                
                externalPriceServiceInput.put('parent', parent);
                externalPriceServiceInput.put('itemList', itemList);
                externalPriceServiceInput.put('pricingVariableToFieldMap', fieldMap);
                externalPriceServiceInput.put('itemFieldsInfo', itemFields);
                externalPriceServiceInput.put('timePlanPolicyList', timePlanPolicyList);
                // skip update to prevent this service from flushing to the database since the pricing plan service
                // will update the itemList anyway, this saves one DML update
                externalPriceServiceOptions.put('SkipUpdate', false);
                
                //This flags will tell if we need to create Adjustment Records for MRC and NRC
                
                externalPriceServiceOptions.put('CreateAdjustment', createAdjustment);
                externalPriceService.invokeMethod('setItemPrices', externalPriceServiceInput, externalPriceServiceOutput, externalPriceServiceOptions);
            }
        }
        Map<String,Object> discInputMap = new Map<String,Object> ();
        Map<String,Object> discOutMap = new Map<String,Object> ();
        Map<String,Object> discOptions = new Map<String,Object> ();
        discInputMap.put('WorkingCartId',(String)input.get('WorkingCartId'));
        discInputMap.put('SalesQuoteId',(String)input.get('SalesQuoteId'));
        discInputMap.put('ContractTerm',(String)input.get('ContractTerm'));
        ATT_CustomDiscountingHelper discountObj = new ATT_CustomDiscountingHelper();
        discountObj.invokeMethod('applyExistingDiscount', discInputMap, discOutMap, discOptions);
        List<String> qlineIds = (List<String>)input.get('quoteLineIds');
        List<QuoteLineItem> a = [SELECT Id,vlocity_cmt__RootItemId__c From QuoteLineItem where id in : qlineIds];
        Map<String,Object> repricingInput = new Map<String,Object>{'objectList' => a};
        repricingInput.put('repriceProvidedLineItemsOnly', false);// mark it true to reprice only provided itemId, else the whole bundle associated with this ItemId needs to get repriced
        Map<String,Object> repricingOutput = new Map<String,Object>();
        Map<String,Object> repricingOptions = new Map<String,Object>();
        vlocity_cmt.VOIInvoker voi = vlocity_cmt.VOIInvoker.getInstance();
        voi.invoke('Repricing', 'repriceLineItems', repricingInput, repricingOutput, repricingOptions);
        
        
        }catch(Exception e){
            System.debug('Exception :: '+e);
        }
    }
}
