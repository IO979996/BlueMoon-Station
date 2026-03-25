import { Fragment } from 'inferno';

import { useBackend } from '../../backend';
import { Box, Button, Flex } from '../../components';
import { connectedToRefList } from './byondPayload';
import { DATATYPE_DISPLAY_HANDLERS, FUNDAMENTAL_DATA_TYPES } from './FundamentalTypes';
import { formatPortLiveValue } from './portValueFormat';

export const DisplayName = (props, context) => {
  const { act, data } = useBackend(context);
  const { port, isOutput, componentId, portIndex, ...rest } = props;
  const isIeCircuit = !!data.ie_circuit;

  const fundamentalType = FUNDAMENTAL_DATA_TYPES[port.type] ? port.type : 'any';
  const InputComponent = FUNDAMENTAL_DATA_TYPES[fundamentalType];
  const TypeDisplayHandler = DATATYPE_DISPLAY_HANDLERS[fundamentalType];

  const connectionRefs = connectedToRefList(port.connected_to);

  const hasInput = !isOutput && !!InputComponent;

  const displayType = port.pin_type_label
    || (TypeDisplayHandler ? TypeDisplayHandler(port) : fundamentalType);
  const showLive = isOutput || !!connectionRefs.length;
  const liveText = showLive
    ? formatPortLiveValue(port.current_data, fundamentalType)
    : null;

  const pdata = port.current_data;
  const liveInspectable = isIeCircuit && (
    fundamentalType === 'list'
    || (pdata !== null && pdata !== undefined && typeof pdata === 'object')
  );

  const openPortInspect = () => {
    if (!isIeCircuit) {
      return;
    }
    if (fundamentalType === 'list') {
      act('ie_open_list_editor', {
        component_id: componentId,
        port_id: portIndex,
        is_output: !!isOutput,
      });
    }
    else {
      act('ie_open_data_inspector', {
        component_id: componentId,
        port_id: portIndex,
        is_output: !!isOutput,
      });
    }
  };

  return (
    <Box {...rest}>
      <Flex direction="column">
        <Flex.Item>
          {(hasInput && (
            <InputComponent
              act={act}
              componentId={componentId}
              portId={portIndex}
              isOutput={isOutput}
              ieCircuit={isIeCircuit}
              setValue={(val, extraParams) =>
                act('set_component_input', {
                  component_id: componentId,
                  port_id: portIndex,
                  input: val,
                  ...extraParams,
                })}
              color={port.color}
              name={port.name}
              value={port.current_data}
              extraData={port.datatype_data}
            />
          ))
            || (isOutput && (
              <Flex align="center" direction="row">
                <Flex.Item>
                  <Button
                    compact
                    color="transparent"
                    icon="comment-dots"
                    tooltip="Показать значение (balloon)"
                    onClick={() =>
                      act('get_component_value', {
                        component_id: componentId,
                        port_id: portIndex,
                      })} />
                </Flex.Item>
                {isIeCircuit && fundamentalType === 'list' && (
                  <Flex.Item>
                    <Button
                      compact
                      color="transparent"
                      icon="list-ul"
                      tooltip="Редактор / просмотр списка"
                      onClick={openPortInspect}
                    />
                  </Flex.Item>
                )}
                <Flex.Item grow>
                  <Box color="white">{port.name}</Box>
                </Flex.Item>
              </Flex>
            ))
            || port.name}
        </Flex.Item>
        <Flex.Item>
          <Box
            fontSize={0.75}
            opacity={0.25}
            textAlign={isOutput ? 'right' : 'left'}>
            {displayType || 'unknown'}
          </Box>
        </Flex.Item>
        {!isOutput && connectionRefs.length >= 1 && (
          <Flex.Item>
            <Box
              fontSize={0.68}
              opacity={0.55}
              mb={0.2}
              textAlign="left"
              className="PortConnectionOrder__caption">
              Порядок связей (как на схеме сверху вниз){connectionRefs.length > 1 ? ' — ⇄ меняет с соседней' : ''}
            </Box>
            <Flex
              align="center"
              wrap="wrap"
              className="PortConnectionOrder">
              {connectionRefs.map((ref, idx) => (
                <Fragment key={ref}>
                  <Box
                    fontSize="0.7rem"
                    opacity={0.72}
                    mx={0.25}
                    unselectable="on"
                    className="PortConnectionOrder__index"
                    title={ref}>
                    #{idx + 1}
                  </Box>
                  {idx < connectionRefs.length - 1 && (
                    <Button
                      compact
                      color="transparent"
                      icon="exchange-alt"
                      tooltip={`Поменять местами #${idx + 1} и #${idx + 2} (линии на поле и порядок на входе)`}
                      mb={0.25}
                      onClick={() =>
                        act('swap_input_connection_order', {
                          component_id: componentId,
                          port_id: portIndex,
                          lower_index: idx + 1,
                        })} />
                  )}
                </Fragment>
              ))}
            </Flex>
          </Flex.Item>
        )}
        {!!showLive && (
          <Flex.Item>
            <Box
              className="PortLiveValue__label"
              textAlign={isOutput ? 'right' : 'left'}>
              значение
            </Box>
            {liveInspectable ? (
              <Box
                className="PortLiveValue PortLiveValue--inspect"
                textAlign={isOutput ? 'right' : 'left'}
                title={
                  fundamentalType === 'list'
                    ? `${liveText} — открыть список`
                    : `${liveText} — открыть полные данные`
                }
                onClick={openPortInspect}>
                {liveText}
              </Box>
            ) : (
              <Box
                className="PortLiveValue"
                textAlign={isOutput ? 'right' : 'left'}
                title={liveText}>
                {liveText}
              </Box>
            )}
          </Flex.Item>
        )}
      </Flex>
    </Box>
  );
};
