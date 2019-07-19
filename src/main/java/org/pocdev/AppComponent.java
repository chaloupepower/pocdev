/*
* Copyright 2019-present Open Networking Foundation
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
package org.pocdev;

import com.google.common.collect.ImmutableSet;
import org.onosproject.cfg.ComponentConfigService;
import org.onosproject.core.ApplicationId;
import org.onosproject.net.host.HostListener;
import org.osgi.service.component.ComponentContext;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Deactivate;
import org.osgi.service.component.annotations.Modified;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Dictionary;
import java.util.Properties;

import static org.onlab.util.Tools.get;

@Component(immediate = true,
service = {SomeInterface.class},
enabled = true
)
public class AppComponent implements SomeInterface {

  private ApplicationId appId;

  private final Logger log = LoggerFactory.getLogger(getClass());

  @Reference(cardinality = ReferenceCardinality.MANDATORY)
  private CoreService coreService;

  @Reference(cardinality = ReferenceCardinality.MANDATORY)
  //Force activation of this component after the pipeconf has been registered.
  @SuppressWarnings("unused")
  protected PipeconfLoader pipeconfLoader;

  @Reference(cardinality = ReferenceCardinality.MANDATORY)
  protected NetworkConfigRegistry configRegistry;

  @Reference(cardinality = ReferenceCardinality.MANDATORY)
  private GroupService groupService;

  @Reference(cardinality = ReferenceCardinality.MANDATORY)
  private DeviceService deviceService;

  @Reference(cardinality = ReferenceCardinality.MANDATORY)
  private FlowRuleService flowRuleService;

  @Reference(cardinality = ReferenceCardinality.MANDATORY)
  private ComponentConfigService compCfgService;

  @Reference(cardinality = ReferenceCardinality.MANDATORY)
  protected ComponentConfigService cfgService;

  @Activate
  protected void activate() {
    log.info("Starting POCapp...");
    cfgService.registerProperties(getClass());
    log.info("Started");
  }

  @Deactivate
  protected void deactivate() {
    log.info("Stopping POCapp...");
    cfgService.unregisterProperties(getClass(), false);
    log.info("Stopped");
  }

  @Modified
  public void modified(ComponentContext context) {
    Dictionary<?, ?> properties = context != null ? context.getProperties() : new Properties();
    if (context != null) {
      baseConf = get(properties, "base config");
    }
    log.info("Reconfigured");
  }

  @Override
  public void someMethod() {
    log.info("Invoked");
  }

  private void setUpTable(DeviceId deviceId) {

    Ip4Address myId = getMyId(deviceId);

    log.info("Adding myId rule on {} (Id {})...", deviceId, myId);

    String tableId = "IngressPipeImpl.my_Id";

    PiCriterion match = PiCriterion.builder()
    .matchLpm(
    PiMatchFieldId.of("hdr.ipv4.dst_addr"),
    myId.toOctets(), 32)
    .build();

    PiTableAction action = PiAction.builder()
    .withId(PiActionId.of("IngressPipeImpl.poc_end"))
    .build();

    FlowRule myStationRule = Utils.buildFlowRule(
    deviceId, appId, tableId, match, action);

    flowRuleService.applyFlowRules(myStationRule);
  }

  public void insertPocInsertRule(DeviceId deviceId, Ip4Address destIp, int prefixLength,
  List<Ip4Address> segmentList) {
    if (segmentList.size() < 2 || segmentList.size() > 3) {
      throw new RuntimeException("List of " + segmentList.size() + " segments is not supported");
    }

    String tableId = "IngressPipeImpl.poc_transit";
    PiCriterion match = PiCriterion.builder()
    .matchLpm(PiMatchFieldId.of("hdr.ipv4.dst_addr"), destIp.toOctets(), prefixLength)
    .build();

    List<PiActionParam> actionParams = Lists.newArrayList();

    for (int i = 0; i < segmentList.size(); i++) {
      PiActionParamId paramId = PiActionParamId.of("s" + (i + 1));
      PiActionParam param = new PiActionParam(paramId, segmentList.get(i).toOctets());
      actionParams.add(param);
    }

    PiAction action = PiAction.builder()
    .withId(PiActionId.of("IngressPipeImpl.poc_t_insert_" + segmentList.size()))
    .withParameters(actionParams)
    .build();
    final FlowRule rule = Utils.buildFlowRule(
    deviceId, appId, tableId, match, action);

    flowRuleService.applyFlowRules(rule);
  }

  public void clearPocInsertRules(DeviceId deviceId) {
    String tableId = "IngressPipeImpl.poc_transit";

    FlowRuleOperations.Builder ops = FlowRuleOperations.builder();
    stream(flowRuleService.getFlowEntries(deviceId))
    .filter(fe -> fe.appId() == appId.id())
    .filter(fe -> fe.table().equals(PiTableId.of(tableId)))
    .forEach(ops::remove);
    flowRuleService.apply(ops.build());
  }

  /*
  Listener of device events.
  */
  public class InternalDeviceListener implements DeviceListener {

    @Override
    public boolean isRelevant(DeviceEvent event) {
      switch (event.type()) {
        case DEVICE_ADDED:
        case DEVICE_AVAILABILITY_CHANGED:
        break;
        default:
        return false;
      }
      final DeviceId deviceId = event.subject().id();
      return mastershipService.isLocalMaster(deviceId);
    }

    @Override
    public void event(DeviceEvent event) {
      final DeviceId deviceId = event.subject().id();
      if (deviceService.isAvailable(deviceId)) {
        mainComponent.getExecutorService().execute(() -> {
          log.info("{} event! deviceId={}", event.type(), deviceId);

          setUpMyIdTable(event.subject().id());
        });
      }
    }
  }

  private synchronized void setUpAllDevices() {
    // Set up host routes
    stream(deviceService.getAvailableDevices())
    .map(Device::id)
    .filter(mastershipService::isLocalMaster)
    .forEach(deviceId -> {
      log.info("*** Poc App - Starting initial set up for {}...", deviceId);
      this.setUpMyIdTable(deviceId);
    });
  }

  /*
  Returns the config for the given device.
  */
  private Optional<SDeviceConfig> getDeviceConfig(DeviceId deviceId) {
    SDeviceConfig config = networkConfigService.getConfig(deviceId, SDeviceConfig.class);
    return Optional.ofNullable(config);
  }

  /*
  Returns Id for the given device.
  */
  private Ip4Address getMyId(DeviceId deviceId) {
    return getDeviceConfig(deviceId)
    .map(DeviceConfig::myId)
    .orElseThrow(() -> new RuntimeException(
    "Missing myId config for " + deviceId));
  }
}
