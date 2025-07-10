import { geoLocationManager } from "@kit.LocationKit"
import { BusinessError } from "@kit.BasicServicesKit"

export function formatDateTime(date: Date): string{
  const  year = date.getFullYear()
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const  day = date.getDate().toString().padStart(2, '0')
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${year}-${month}-${day} ${hours}:${minutes}`
}

const TAG: string = 'GRLocation';

/**
 * 获取系统缓存的最新位置
 * 如果系统当前没有缓存位置会返回错误码。
 * 推荐优先使用该接口获取位置，可以减少系统功耗。
 * 如果对位置的新鲜度比较敏感，可以先获取缓存位置，将位置中的时间戳与当前时间对比，若新鲜度不满足预期可以使用方式二获取位置
 *
 * @returns 缓存的最新位置
 */
export function getLastLocation(): geoLocationManager.Location | undefined {
  try {
    let location = geoLocationManager.getLastLocation();
    return location;
  } catch (err) {
    console.info(TAG, "errCode:" + err.code + ", message:" + err.message);
    return undefined;
  }
}

/**
 * 获取当前位置, 通过本模块获取到的坐标均为WGS-84坐标系坐标点
 * 坐标转换：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V14/map-convert-coordinate-V14
 *
 * 首先要实例化SingleLocationRequest对象，用于告知系统该向应用提供何种类型的位置服务，以及单次定位超时时间。
 *
 * 设置LocatingPriority：
 *  如果对位置的返回精度要求较高，建议LocatingPriority参数优先选择PRIORITY_ACCURACY，会将一段时间内精度较好的结果返回给应用。
 *  如果对定位速度要求较高，建议LocatingPriority参数选择PRIORITY_LOCATING_SPEED，会将最先拿到的定位结果返回给应用。
 *  两种定位策略均会同时使用GNSS定位和网络定位技术，以便在室内和户外场景下均可以获取到位置结果，对设备的硬件资源消耗较大，功耗也较大。
 *
 * 设置locatingTimeoutMs：
 * 因为设备环境、设备所处状态、系统功耗管控策略等的影响，定位返回的时延会有较大波动，建议把单次定位超时时间设置为10秒。
 */
export function getCurrentLocation() {
  let request: geoLocationManager.SingleLocationRequest = {
    'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
    'locatingTimeoutMs': 10000
  }
  try {
    geoLocationManager.getCurrentLocation(request).then((result) => { // 调用getCurrentLocation获取当前设备位置，通过promise接收上报的位置
      console.info(TAG, 'current location: ' + JSON.stringify(result));
    })
      .catch((error: BusinessError) => { // 接收上报的错误码
        console.info(TAG, 'promise, getCurrentLocation: error=' + JSON.stringify(error));
      });
  } catch (err) {
    console.info(TAG, "errCode:" + JSON.stringify(err));
  }
}

export function parseTimerStr(timerStr: string): Date{
  const now = new Date()
  console.log("Home", timerStr)
  const time = timerStr.split(":").map(Number)
  console.log("HomeHours", time)

  return new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate(),
    time[0],
    time[1]
  )
}

export function getMinutesDifference(target: Date): number{
  const now = new Date()

  console.log("Home", target.getTime(), "-", now.getTime())

  const diffMs = target.getTime() - now.getTime()

  console.log("Home", diffMs)

  return Math.round(diffMs / (1000 * 60))
}