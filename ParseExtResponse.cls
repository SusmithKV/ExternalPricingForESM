public class ParseExtResponse {
   // Added changes related to copy config-27073

    public String quoteMemberId;
    public String customerName;
    public Address address;
    public Double latitude;
    public Double longitude;
    public String npanxx;
    public String visibilityType;
    public String probBuildDesc;
    public String probBuildWithRes;
    public String matchStatus;
    public String matchLevel;
    public String matchScore;
    public String accessArrangement;
    public BandwidthQuote bandwidthQuote;
    public String responseMessage;
    public String code;
    public String message;
    public String description;
    public String traceId;
    public String transactionId;
    public String node;

    public class Address {
        public String addressLine1;
        public String city;
        public String postalCode;
        public String postalCodeExtension;
        public String province;
        public String countryIso;
    }

    public class CustomerPrefVendors {
        public PreferredVendorName preferredVendorName;
    }

    public class CustomerAvoidedVendors {
        public PreferredVendorName avoidedVendorName;
    }

    public class PreferredVendorName {
    }

    public class Node {
        public String clli;
        public String localCurrency;
        public String swclli;
        public String quoteExpirationDate;
        public String coverageIndicator;
        public String quoteQualifiedAsRequested;
        public String bandwidthMet;
        public String architectureMet;
        public Boolean vendorPreferenceRequested;
        public String serialNumber;
        public String providerProductName;
        public Integer quoteDaysTtl;
        public List<PreferredVendorName> usClecDisplays;
        public ContractTerm contractTerm;
    }

    public class ProductDesignDetails {
        public String service;
        public String accessTransport;
        public String accessArchitecture;
        public String accessTechnology;
        public String accessTail;
        public String accessInterconnectTechnology;
        public String cmtu;
        public String portLevelCos;
        public String accessSpeed;
        public String accessSpeedRequested;
        public String accessArchitectureRequested;
        public String physicalInterface;
        public String onnetCheck;
        public String zone;
    }

    public class ContractTerm {
        public Double oneTimePriceUsd;
        public Double baseMonthlyPriceLocal;
        public Double baseMonthlyPriceUsd;
        public Double monthlyPriceLocal;
        public Double monthlyPriceUsd;
        public String contractDuration;
        public Double oneTimePriceLocal;
    }

    public class AccessSupplier {
        public String ituCode;
        public String pmtu;
        public String supplierName;
        public String mtuSupportMessage;
        public Integer leadTime;
        public Node node;
    }

    public class BandwidthQuote {
        public String ethernetTokenId;
        public String errorMessage;
        public Integer discountPercentage;
        public String quoteRequestDate;
        public String pricingTier;
        public Decimal billableMileage;
        public Decimal swcToSwcMileage;
        public String pricingZone;
        public String serviceGuideEligible;
        public List<CustomerPrefVendors> customerPrefVendors;
        public List<CustomerAvoidedVendors> customerAvoidedVendors;
        public AccessSupplier accessSupplier;
        public String ethernetIoc;
        public String availability;
        public ProductDesignDetails productDesignDetails;
    }

    
    public static ParseExtResponse parse(String json) {
        System.debug('Json ::: '+json);
        return (ParseExtResponse) System.JSON.deserialize(json, ParseExtResponse.class);
    }
}
