import axios, { type AxiosInstance } from "axios";

export interface TheorosSDKConfig {
  baseUrl?: string;
  timeout?: number;
}

export interface CalldataResponse {
  calldata: number[];
}

export class TheorosSDK {
  private baseUrl: string;
  private httpClient: AxiosInstance;

  constructor(config: TheorosSDKConfig) {
    this.baseUrl = config.baseUrl || "https://api.pragma.build/v1";

    this.httpClient = axios.create({
      baseURL: this.baseUrl,
      timeout: config.timeout || 10000,
      headers: {
        "Content-Type": "application/json",
      },
    });
  }

  // Fetch available data feeds
  async getAvailableFeedIds(): Promise<string[]> {
    try {
      const response = await this.httpClient.get<string[]>("/data_feeds");
      return response.data;
    } catch (error) {
      throw new Error(`Error fetching data feeds: ${error}`);
    }
  }

  // Fetch calldata for a given Feed ID
  async getCalldata(feedId: string): Promise<CalldataResponse> {
    try {
      const response = await this.httpClient.get<CalldataResponse>(
        `/calldata/${feedId}`,
      );
      return response.data;
    } catch (error) {
      throw new Error(
        `Error fetching calldata for feed ID ${feedId}: ${error}`,
      );
    }
  }
}
