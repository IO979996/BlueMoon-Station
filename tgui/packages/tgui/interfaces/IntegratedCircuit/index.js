import { Component } from 'inferno';

import { resolveAsset } from '../../assets';
import { useBackend } from '../../backend';
import {
  Box,
  Button,
  InfinitePlane,
  Input,
  Stack,
} from '../../components';
import { Window } from '../../layouts';
import { CircuitInfo } from './CircuitInfo';
import { CircuitToolbar } from './CircuitToolbar';
import { Connections } from './Connections';
import { ABSOLUTE_Y_OFFSET, MOUSE_BUTTON_LEFT } from './constants';
import { byondListToArray, normalizeCircuitComponent } from './byondPayload';
import { ObjectComponent } from './ObjectComponent';
import { VariableMenu } from './VariableMenu';

export class IntegratedCircuit extends Component {
  constructor() {
    super();
    this.state = {
      locations: {},
      selectedPort: null,
      mouseX: null,
      mouseY: null,
      zoom: 1,
      backgroundX: 0,
      backgroundY: 0,
      menuOpen: false,
    };
    this.handlePortLocation = this.handlePortLocation.bind(this);
    this.handleMouseDown = this.handleMouseDown.bind(this);
    this.handleMouseUp = this.handleMouseUp.bind(this);
    this.handlePortClick = this.handlePortClick.bind(this);
    this.handlePortRightClick = this.handlePortRightClick.bind(this);
    this.handlePortUp = this.handlePortUp.bind(this);

    this.handlePortDrag = this.handlePortDrag.bind(this);
    this.handlePortRelease = this.handlePortRelease.bind(this);
    this.handleZoomChange = this.handleZoomChange.bind(this);
    this.handleBackgroundMoved = this.handleBackgroundMoved.bind(this);
  }

  // Helper function to get an element's exact position
  getPosition(el) {
    let xPos = 0;
    let yPos = 0;

    while (el) {
      xPos += el.offsetLeft;
      yPos += el.offsetTop;
      el = el.offsetParent;
    }
    return {
      x: xPos,
      y: yPos + ABSOLUTE_Y_OFFSET,
    };
  }

  handlePortLocation(port, dom) {
    const { locations } = this.state;

    if (!dom) {
      return;
    }

    const lastPosition = locations[port.ref];
    const position = this.getPosition(dom);
    position.color = port.color;

    if (
      isNaN(position.x)
      || isNaN(position.y)
      || (lastPosition
        && lastPosition.x === position.x
        && lastPosition.y === position.y)
    ) {
      return;
    }
    locations[port.ref] = position;
    this.setState({ locations: locations });
  }

  handlePortClick(portIndex, componentId, port, isOutput, event) {
    if (event.button !== MOUSE_BUTTON_LEFT) {
      return;
    }

    event.stopPropagation();
    this.setState({
      selectedPort: {
        index: portIndex,
        component_id: componentId,
        is_output: isOutput,
        ref: port.ref,
      },
    });

    this.handlePortDrag(event);

    window.addEventListener('mousemove', this.handlePortDrag);
    window.addEventListener('mouseup', this.handlePortRelease);
  }

  // mouse up called whilst over a port. This means we can check if selectedPort
  // exists and do perform some actions if it does.
  handlePortUp(portIndex, componentId, port, isOutput, event) {
    const { act } = useBackend(this.context);
    const {
      selectedPort,
    } = this.state;
    if (!selectedPort) {
      return;
    }
    if (selectedPort.is_output === isOutput) {
      return;
    }
    let data;
    if (isOutput) {
      data = {
        input_port_id: selectedPort.index,
        output_port_id: portIndex,
        input_component_id: selectedPort.component_id,
        output_component_id: componentId,
      };
    } else {
      data = {
        input_port_id: portIndex,
        output_port_id: selectedPort.index,
        input_component_id: componentId,
        output_component_id: selectedPort.component_id,
      };
    }
    act("add_connection", data);
  }

  handlePortDrag(event) {
    const { data } = useBackend(this.context);
    const { screen_x, screen_y } = data;
    this.setState((state) => ({
      mouseX: event.clientX - (state.backgroundX || screen_x),
      mouseY: event.clientY - (state.backgroundY || screen_y),
    }));
  }

  handlePortRelease(event) {
    this.setState({
      selectedPort: null,
    });

    window.removeEventListener('mousemove', this.handlePortDrag);
    window.removeEventListener('mouseup', this.handlePortRelease);
  }

  handlePortRightClick(portIndex, componentId, port, isOutput, event) {
    const { act } = useBackend(this.context);

    event.preventDefault();
    act('remove_connection', {
      component_id: componentId,
      is_input: !isOutput,
      port_id: portIndex,
    });
  }

  handleZoomChange(newZoom) {
    this.setState({
      zoom: newZoom,
    });
  }

  handleBackgroundMoved(newX, newY) {
    this.setState({
      backgroundX: newX,
      backgroundY: newY,
    });
    if (this.state.menuOpen) {
      this.setState({
        menuOpen: false,
      });
    }
  }

  componentDidMount() {
    window.addEventListener('mousedown', this.handleMouseDown);
    window.addEventListener('mouseup', this.handleMouseUp);
  }

  componentWillUnmount() {
    window.removeEventListener('mousedown', this.handleMouseDown);
    window.removeEventListener('mouseup', this.handleMouseUp);
  }

  handleMouseDown(event) {
    const { act, data } = useBackend(this.context);
    const { examined_name } = data;
    if (examined_name) {
      act('remove_examined_component');
    }
  }

  handleMouseUp(event) {
    const { act } = useBackend(this.context);
    const { backgroundX, backgroundY } = this.state;
    if (backgroundX && backgroundY) {
      act("move_screen", {
        screen_x: backgroundX,
        screen_y: backgroundY,
      });
    }
  }

  render() {
    const { act, data } = useBackend(this.context);
    const {
      circuit_on,
      display_name,
      examined_name,
      examined_desc,
      examined_notices,
      examined_rel_x,
      examined_rel_y,
      screen_x,
      screen_y,
      is_admin,
      variables,
      global_basic_types,
      ie_circuit,
    } = data;
    const components = byondListToArray(data.components).map(
      normalizeCircuitComponent,
    );
    const ieBatteryPercent = ie_circuit && data.ie_battery_percent !== undefined
      ? data.ie_battery_percent
      : undefined;
    const { locations, selectedPort, menuOpen, zoom } = this.state;
    const connections = [];
    const componentCount = components.reduce((n, c) => n + (c ? 1 : 0), 0);
    const variableCount = variables?.length ?? 0;
    const zoomPercent = Math.round((zoom || 1) * 100);

    for (const comp of components) {
      if (comp === null) {
        continue;
      }

      const inputPorts = byondListToArray(comp.input_ports);
      for (const input of inputPorts) {
        const linked = byondListToArray(input?.connected_to);
        for (const output of linked) {
          const output_port = locations[output];
          connections.push({
            color: (output_port && output_port.color) || 'blue',
            from: output_port,
            to: locations[input.ref],
          });
        }
      }
    }

    if (selectedPort) {
      const { mouseX, mouseY, zoom } = this.state;
      const isOutput = selectedPort.is_output;
      const portLocation = locations[selectedPort.ref];
      const mouseCoords = {
        x: (mouseX)*Math.pow(zoom, -1),
        y: (mouseY + ABSOLUTE_Y_OFFSET)*Math.pow(zoom, -1),
      };
      connections.push({
        color: (portLocation && portLocation.color) || 'blue',
        from: isOutput? portLocation : mouseCoords,
        to: isOutput? mouseCoords : portLocation,
      });
    }

    return (
      <Window
        width={920}
        height={720}
        buttons={(
          <Box
            minWidth="280px"
            maxWidth="420px"
            position="absolute"
            top="4px"
            height="24px"
          >
            <Stack>
              <Stack.Item grow>
                <Input
                  fluid
                  placeholder={ie_circuit
                    ? 'Имя корпуса (не поиск по деталям)'
                    : 'Имя схемы'}
                  value={display_name}
                  onChange={(e, value) => act("set_display_name", { display_name: value })}
                />
              </Stack.Item>
              {!ie_circuit && (
                <Stack.Item>
                  <Button
                    color="transparent"
                    icon="cog"
                    tooltip="Переменные и сеттеры/геттеры"
                    selected={menuOpen}
                    onClick={() => this.setState((state) => ({
                      menuOpen: !state.menuOpen,
                    }))}
                  />
                </Stack.Item>
              )}
              {!!is_admin && !ie_circuit && (
                <Stack.Item>
                  <Button
                    color="transparent"
                    tooltip="Сохранить схему (JSON)"
                    onClick={() => act("save_circuit")}
                    icon="save"
                  />
                </Stack.Item>
              )}
            </Stack>
          </Box>
        )}
      >
        <Window.Content
          fitted
          className="IntegratedCircuit__content"
          style={{
            'background-image': 'none',
          }}>
          <Box className="IntegratedCircuit__frame">
            <CircuitToolbar
              circuitOn={circuit_on}
              componentCount={componentCount}
              variableCount={variableCount}
              zoomPercent={zoomPercent}
              showVariableChip={!ie_circuit}
              ieBatteryPercent={ieBatteryPercent}
            />
            <Box className="IntegratedCircuit__planeHost">
              <InfinitePlane
                width="100%"
                height="100%"
                backgroundImage={resolveAsset('grid_background.png')}
                imageWidth={1200}
                onZoomChange={this.handleZoomChange}
                onBackgroundMoved={this.handleBackgroundMoved}
                initialLeft={screen_x}
                initialTop={screen_y}
              >
                {components.map(
                  (comp, index) =>
                    comp && (
                      <ObjectComponent
                        key={index}
                        {...comp}
                        index={index + 1}
                        circuitOn={circuit_on ?? true}
                        onPortUpdated={this.handlePortLocation}
                        onPortLoaded={this.handlePortLocation}
                        onPortMouseDown={this.handlePortClick}
                        onPortRightClick={this.handlePortRightClick}
                        onPortMouseUp={this.handlePortUp}
                      />
                    )
                )}
                <Connections connections={connections} />
              </InfinitePlane>
            </Box>
          </Box>
          {!!examined_name && (
            <CircuitInfo
              position="absolute"
              className="CircuitInfo__Examined"
              top={`${examined_rel_y}px`}
              left={`${examined_rel_x}px`}
              name={examined_name}
              desc={examined_desc}
              notices={examined_notices}
            />
          )}
          {!!menuOpen && !ie_circuit && (
            <Box
              className="IntegratedCircuit__variableDock"
              position="absolute"
              bottom={0}
              left={0}
              height="50%"
              minHeight="300px"
              width="100%"
            >
              <VariableMenu
                variables={variables}
                types={global_basic_types}
                onAddVariable={(name, type, event) => act("add_variable", {
                  variable_name: name,
                  variable_datatype: type,
                })}
                onRemoveVariable={(name, event) => act("remove_variable", {
                  variable_name: name,
                })}
                handleAddSetter={(e) => act("add_setter_or_getter", {
                  is_setter: true,
                })}
                handleAddGetter={(e) => act("add_setter_or_getter", {
                  is_setter: false,
                })}
              />
            </Box>
          )}
        </Window.Content>
      </Window>
    );
  }
}

