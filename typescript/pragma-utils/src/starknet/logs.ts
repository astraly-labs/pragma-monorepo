import { isArray, mapValues } from "lodash-es";

function stringifyAddresses(value: any): any {
  if (isArray(value)) {
    return value.map(stringifyAddresses);
  }
  return value?.address ? value.address : value;
}

export function logAddresses(label: string, records: Record<string, any>) {
  records = mapValues(records, stringifyAddresses);
  console.log(label, records);
}
