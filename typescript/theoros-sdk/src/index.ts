import axios, { type AxiosInstance } from "axios";
import { EventEmitter } from "events";

export interface TheorosSDKConfig {
  baseUrl?: string;
  timeout?: number;
}

export interface CalldataResponse {
  feed_id: string;
  encoded_calldata: string;
}

export interface Feed {
  feed_id: string;
  asset_class: string;
  feed_type: string;
  pair_id: string;
}

export interface RpcDataFeed {
  feed_id: string;
  encoded_calldata: string;
}

export class TheorosSDKError extends Error {
  public cause?: any;
  constructor(message: string, cause?: any) {
    super(message);
    this.name = "TheorosSDKError";
    this.cause = cause;
  }
}

export class Subscription extends EventEmitter {
  private socket!: WebSocket;
  private isClosed = false;
  private chain: string;
  private feedIds: Set<string>;
  private baseUrl: string;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;

  constructor(baseUrl: string, chain: string, feedIds: string[]) {
    super();
    this.baseUrl = baseUrl;
    this.chain = chain;
    this.feedIds = new Set(feedIds);
    this.connect();
  }

  private connect() {
    const wsUrl = this.baseUrl.replace(/^http/, "ws") + "/ws";
    this.socket = new WebSocket(wsUrl);

    this.socket.addEventListener("open", () => {
      this.reconnectAttempts = 0;
      const subscribeMessage = JSON.stringify({
        type: "subscribe",
        chain: this.chain,
        feed_ids: Array.from(this.feedIds),
      });
      this.socket.send(subscribeMessage);
      this.emit("open");
    });

    this.socket.addEventListener("message", (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === "data_feed_update") {
          this.emit("update", data.data_feeds as RpcDataFeed[]);
        } else if (data.type === "response") {
          if (data.status === "error") {
            this.emit("error", new TheorosSDKError(data.error));
          } else if (data.status === "success") {
            // Optional: Handle success responses if needed
          }
        }
      } catch (e) {
        this.emit(
          "error",
          new TheorosSDKError("Invalid JSON message received", e),
        );
      }
    });

    this.socket.addEventListener("error", (event) => {
      this.emit("error", new TheorosSDKError("WebSocket error", event));
    });

    this.socket.addEventListener("close", () => {
      this.emit("close");
      if (
        !this.isClosed &&
        this.reconnectAttempts < this.maxReconnectAttempts
      ) {
        const timeout = Math.pow(2, this.reconnectAttempts) * 1000;
        this.reconnectAttempts += 1;
        setTimeout(() => this.connect(), timeout);
      } else if (!this.isClosed) {
        this.emit(
          "error",
          new TheorosSDKError("Max reconnection attempts reached"),
        );
      }
    });
  }

  /**
   * Adds new feed IDs to the subscription.
   * @param feedIds - Array of feed IDs to subscribe to.
   */
  addFeedIds(feedIds: string[]) {
    for (const id of feedIds) {
      if (!this.feedIds.has(id)) {
        this.feedIds.add(id);
        if (this.socket.readyState === WebSocket.OPEN) {
          const subscribeMessage = JSON.stringify({
            type: "subscribe",
            chain: this.chain,
            feed_ids: [id],
          });
          this.socket.send(subscribeMessage);
        }
      }
    }
  }

  /**
   * Removes feed IDs from the subscription.
   * @param feedIds - Array of feed IDs to unsubscribe from.
   */
  removeFeedIds(feedIds: string[]) {
    for (const id of feedIds) {
      if (this.feedIds.has(id)) {
        this.feedIds.delete(id);
        if (this.socket.readyState === WebSocket.OPEN) {
          const unsubscribeMessage = JSON.stringify({
            type: "unsubscribe",
            feed_ids: [id],
          });
          this.socket.send(unsubscribeMessage);
        }
      }
    }
  }

  /**
   * Unsubscribes from all feeds and closes the WebSocket connection.
   */
  unsubscribe() {
    this.isClosed = true;
    if (this.socket.readyState === WebSocket.OPEN) {
      const unsubscribeMessage = JSON.stringify({
        type: "unsubscribe",
        feed_ids: Array.from(this.feedIds),
      });
      this.socket.send(unsubscribeMessage);
      this.socket.close();
    } else {
      this.socket.close();
    }
  }
}

export class TheorosSDK {
  private baseUrl: string;
  private httpClient: AxiosInstance;

  constructor(config: TheorosSDKConfig = {}) {
    this.baseUrl = config.baseUrl || "https://api.pragma.build/v1";

    this.httpClient = axios.create({
      baseURL: this.baseUrl,
      timeout: config.timeout || 10000,
      headers: {
        "Content-Type": "application/json",
      },
    });
  }

  /**
   * Retrieves all available data feeds.
   * @returns A promise that resolves to an array of Feed objects.
   */
  async getAvailableFeeds(): Promise<Feed[]> {
    try {
      const response = await this.httpClient.get<Feed[]>("/data_feeds");
      return response.data;
    } catch (error) {
      throw new TheorosSDKError("Error fetching data feeds", error);
    }
  }

  /**
   * Retrieves all supported chains.
   * @returns A promise that resolves to an array of chain names.
   */
  async getSupportedChains(): Promise<string[]> {
    try {
      const response = await this.httpClient.get<string[]>("/chains");
      return response.data;
    } catch (error) {
      throw new TheorosSDKError("Error fetching supported chains", error);
    }
  }

  /**
   * Fetches calldata for the specified chain and feed IDs.
   * @param chain - The chain name.
   * @param feedIds - An array of feed IDs.
   * @returns A promise that resolves to an array of CalldataResponse objects.
   */
  async getCalldata(
    chain: string,
    feedIds: string[],
  ): Promise<CalldataResponse[]> {
    try {
      const params = {
        chain,
        feed_ids: feedIds.join(","),
      };
      const response = await this.httpClient.get<CalldataResponse[]>(
        "/calldata",
        { params },
      );
      return response.data;
    } catch (error) {
      throw new TheorosSDKError("Error fetching calldata", error);
    }
  }

  /**
   * Subscribes to data feed updates over WebSocket.
   * @param chain - The chain name.
   * @param feedIds - An array of feed IDs.
   * @returns A Subscription object that emits events on data updates.
   */
  subscribe(chain: string, feedIds: string[]): Subscription {
    return new Subscription(this.baseUrl, chain, feedIds);
  }
}
