export interface DeploymentConfig {
  pragma_oracle: {
    pairs: string[];
    publishers: Array<{
      name: string;
      address: string;
      sources: string[];
    }>;
  };
  pragma_dispatcher: {
    owner?: string;
    pragma_oracle_address: string;
    hyperlane_mailbox_address: string;
  };
  pragma: {
    data_source_emitters: Array<{
      chain_id: number;
      address: string;
    }>;
    valid_time_period_in_seconds: number;
    single_update_fee_in_wei: string;
    hyperlane: {
      validators: string[];
    };
  };
}
